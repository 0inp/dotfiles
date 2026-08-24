---
name: sillant-pr-review
description: Review d'une PR Sillant — choisit le mode (double passe indépendante ou passe simple) et le périmètre (complet ou incrémental) selon mes reviews précédentes, puis publie une review unique. Use when reviewing a Sillant PR, from the gh-dash R keybinding or via /sillant-pr-review <pr>.
---

# Review d'une PR Sillant — mode et périmètre

Surcouche **personnelle** au `/pr-review` de `sillant-context`. Ce fichier décide
**comment** reviewer : combien de passes, sur quel périmètre. Les **critères**, les deux
axes de classement (sévérité + vérification) et la table de verdict restent ceux de
`sillant-context/commands/pr-review-core.md` — ne pas les redire ici, les appliquer.

## Étape 1 — Déterminer le mode

Une seule question : **ai-je déjà reviewé cette PR ?** Les reviews des collègues et des
bots ne comptent pas ici — elles servent au dédoublonnage (étape 5), jamais au mode ni au
périmètre.

### Ne pas confondre une review et une réponse de thread [MUST]

GitHub emballe **chaque réponse inline dans un enregistrement de review** de state
`COMMENTED` et de body vide. Sur une PR dont je suis l'auteur, `/pr-comments` répond aux
bots et fabrique ainsi 5 ou 6 « reviews » à mon nom — vérifié sur `vicat#699`, où mes six
enregistrements sont tous des réponses de thread et aucun n'est une vraie review. Filtrer
uniquement sur le `state` classerait donc la PR en mode SUIVI et poserait une baseline sur
l'horodatage d'une réponse : le périmètre se réduirait en silence et le diff réel serait
sauté presque entièrement.

Une review compte comme **la mienne** seulement si elle est un acte délibéré :

- state `APPROVED` ou `CHANGES_REQUESTED` ; **ou**
- body non vide ; **ou**
- elle porte au moins un commentaire inline de moi **qui n'est pas une réponse**
  (`in_reply_to_id` absent).

C'est le troisième critère qui porte le poids : mes reviews sont postées en inline-only
avec un body vide, donc le body ne discrimine rien.

```bash
PR="$1"; ME=$(gh api user --jq '.login')
REAL=$(gh api "repos/{owner}/{repo}/pulls/$PR/comments" --paginate \
  | jq -c --arg me "$ME" '[.[]|select(.user.login==$me and (.in_reply_to_id|not))
                            |.pull_request_review_id]|unique')
gh api "repos/{owner}/{repo}/pulls/$PR/reviews" --paginate \
  | jq -r --arg me "$ME" --argjson real "$REAL" '
      [ .[]
        | select(.user.login == $me)
        | select( . as $r
                  | ($r.state == "APPROVED")
                 or ($r.state == "CHANGES_REQUESTED")
                 or ((($r.body // "") | length) > 0)
                 or (($real | index($r.id)) != null) ) ]
      | if length == 0 then "AUCUNE"
        else (sort_by(.submitted_at) | last
              | "\(.state) \(.commit_id) \(.submitted_at)") end'
```

- `AUCUNE` → **mode PREMIÈRE** : double passe indépendante, périmètre complet (étape 3).
- Sinon → **mode SUIVI** : passe simple, périmètre à calculer (étape 2). La baseline est
  le `commit_id` retourné.

Annoncer le mode retenu en une ligne avant de commencer, avec la baseline le cas échéant.

## Étape 2 — Déterminer le périmètre (mode SUIVI uniquement)

### Le garde d'ancêtre [MUST]

**Ne jamais calculer un diff incrémental sans ce garde.** GitHub ne relie ma review à un
diff partiel que tant que le SHA reviewé est encore un **ancêtre** du head. Un rebase ou un
force-push le rend orphelin ; `git diff <baseline>...<head>` n'échoue alors pas, il fait
silencieusement retomber la merge-base sur un vieux commit de `main` et rend un diff qui
mélange tout ce que `main` a fait entre-temps.

```bash
HEAD_SHA=$(gh pr view "$PR" --json headRefOid --jq '.headRefOid')
git fetch origin "pull/$PR/head" --quiet 2>/dev/null
if ! git cat-file -e "${BASELINE}^{commit}" 2>/dev/null; then
  echo "FULL — baseline absente en local"
elif git merge-base --is-ancestor "$BASELINE" "$HEAD_SHA" 2>/dev/null; then
  echo "INCREMENTAL — $(git rev-list --count "${BASELINE}..${HEAD_SHA}") commit(s), \
$(git diff --name-only "${BASELINE}..${HEAD_SHA}" | wc -l | tr -d ' ') fichier(s)"
else
  echo "FULL — force-push, baseline orpheline"
fi
```

**Zéro commit depuis la baseline → ne rien reviewer.** Répondre « aucun nouveau commit
depuis ma dernière review, elle tient toujours » et s'arrêter là. Ne pas re-poster les
findings précédents.

SHA absent en local ou non-ancêtre → **périmètre complet**, et le dire explicitement dans
la review : « ta branche a été rebasée depuis ma dernière review, je repars du diff
complet ».

### Escalade automatique vers le périmètre complet

Un seul de ces cas suffit, sans discussion :

- baseline orpheline ou absente (ci-dessus) ;
- le diff depuis la baseline touche une **migration**, un **contrat d'API**, ou un
  **type/enum partagé** consommé ailleurs ;
- le scope de l'issue Linear ou la description de la PR a changé depuis la baseline.

### Escalade sur jugement

Annoncer la décision et la raison, dans un sens comme dans l'autre :

- plus de ~15 fichiers ou ~400 lignes changées depuis la baseline ;
- les nouveaux commits changent le **comportement** de code déjà reviewé, au lieu de
  simplement traiter mes commentaires.

Sinon → **périmètre incrémental** : `git diff "$BASELINE".."$HEAD_SHA"` (deux points, pas
trois — la merge-base ne sert à rien ici et c'est elle qui ment après un rebase).

Dans tous les cas, lire le diff **complet** de la PR au moins en survol pour le contexte ;
ne restreindre que le périmètre des **findings postés**.

## Étape 3 — Mode PREMIÈRE : deux passes indépendantes

Lancer **deux sous-agents en parallèle**. Aucun ne voit la sortie de l'autre — c'est toute
la valeur du dispositif. Les deux ont le **même mandat complet** (mêmes critères, mêmes
règles, tout le diff), mais un **angle d'entrée différent**, pour qu'ils ne se corrèlent
pas :

- **Passe A — depuis le diff.** Fichier par fichier, ligne par ligne : quelle règle est
  violée ici ? Remonte du code vers l'intention.
- **Passe B — depuis l'intention.** Part de l'issue Linear (description + commentaire
  `<!-- agent-plan -->`) : quel comportement était visé ? Le code le produit-il, et où
  dévie-t-il ? Descend de l'intention vers le code.

Chaque passe rend ses findings au format du core (sévérité + vérif + vérificateur). Ne
jamais lancer la passe B après la passe A en lui donnant ses résultats.

## Étape 4 — Fusionner les deux passes

1. **Union** des findings, dédoublonnés par `(fichier, ligne, règle)`.
2. **Désaccord → le plus strict gagne** : sévérité la plus haute, et `REVIEW` l'emporte
   sur `AUTO`.
3. **Un finding trouvé par une seule passe n'est pas écarté** — il est vérifié une fois
   contre le code avant d'être posté. Deux passes qui le trouvent = signal de confiance ;
   une seule = à confirmer, pas à jeter.

Le résultat est **une seule review**. Ne jamais publier deux reviews.

## Étape 5 — Dédoublonner contre les reviews existantes

Lire les reviews déjà postées sur la PR (collègues **et** Copilot/bots) et retirer tout
finding déjà soulevé. Ne pas re-dire ce qu'un autre a déjà écrit.

## Étape 6 — Publier

- **Une seule review**, commentaires **inline** uniquement, ancrés sur des lignes
  effectivement changées. Pas de corps de résumé.
- Tout écrire en **français**.
- **Verdict** selon la table du core : 0 CRITICAL et tous les findings en `AUTO` →
  **approuver la PR** avec les commentaires, en précisant « merge après traitement des N
  commentaires ci-dessus ». Ne pas retenir l'approbation par prudence quand tout est AUTO.
- Rien à signaler → approuver.
