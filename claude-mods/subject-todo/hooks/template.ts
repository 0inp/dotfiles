// The default list for a ticket. Claude adapts it per ticket with the
// subject_todo tool (`replace`); edit here to change the workflow itself.
export const TICKET_TEMPLATE: readonly string[] = [
  'Lire le ticket et comprendre le sujet',
  'Écrire la fiche de cadrage',
  'Relire la fiche de cadrage et la corriger si nécessaire',
  '1ère implémentation',
  'Préparer la QA de dev manuelle',
  'Faire la QA de dev',
  'Corriger les retours de QA',
  'Ouvrir les PRs en ready-to-review',
  'Adresser les commentaires de PRs',
  'Merge',
  'Nettoyer : worktrees, fiche doc, branches git, etc.',
]
