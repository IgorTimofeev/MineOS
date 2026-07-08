-- shared/reactors.lua
-- Machines HBM à superviser (réacteurs / gros consommateurs d'énergie).
-- Lues via l'addon OC HBM (composants hbm_reactor / hbm_machine). Ajouter une machine = une entrée.

local reactors = {}

reactors.CONFIG = {
  {
    id = "reactor_1",
    name = "Réacteur principal",
    address = "REPLACE_WITH_HBM_REACTOR_ADDRESS", -- composant hbm_reactor
    tempWarn = 800,   -- seuil d'avertissement
    tempCrit = 1000,  -- seuil critique (déclenche alarme + SCRAM auto si activé)
    autoScram = true, -- arrêt d'urgence automatique au seuil critique
  },
  {
    id = "grid",
    name = "Réseau énergie",
    address = "REPLACE_WITH_HBM_MACHINE_ADDRESS", -- composant hbm_machine (getEnergy)
    energyOnly = true, -- pas de température : supervision d'énergie seule
  },
}

function reactors.get(id)
  for _, r in ipairs(reactors.CONFIG) do
    if r.id == id then return r end
  end
  return nil
end

return reactors
