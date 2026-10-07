# Préférences globales

## Autonomie

Quand une étape ne demande pas mon avis, continue. Arrête-toi pour demander seulement si tu ne
peux pas avancer sans moi, ou avant une action destructive ou visible hors de cette machine.
Mets les notes d'avancement dans le même message que l'action suivante. Les points d'arrêt
qu'un repo définit dans son propre `CLAUDE.md` (un GO avant de coder, une validation avant
commit) priment sur cette règle.

## Attendre une tâche de fond

Un sous-agent ou une commande en arrière-plan te réveille à sa fin : attends sa
notification. Pour une attente que rien ne notifie (CI, déploiement), surveille avec
`Monitor` ou un `gh run watch` en arrière-plan.

## Fin de run

Une tâche qui modifie des fichiers ou enchaîne plusieurs étapes se termine sur trois
rubriques, dans cet ordre : **Bloqué sur moi**, **Changé**, **Trouvé**. Une rubrique vide
s'écrit « rien ». Une question simple reçoit une réponse directe, sans ces rubriques.

## Non vérifié

Marque chaque affirmation que tu n'as pas pu confirmer, et dis où tu as cherché.
