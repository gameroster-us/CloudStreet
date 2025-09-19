class ResetFlagToRunOneTimeScriptOnSeed < ActiveRecord::Migration[5.1]
  def change
    # We need to add Directive services for Generic Services so need to run one time method onetime_method again.
    srs = ScriptRunStatus.where(script_type: 'seed_first_deployment_tasks').first
    srs.update(run_status: false) if srs.present?
  end
end
