module WorkspacesRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  collection(
  :workspaces, 
  class: Workspace,
  extend: WorkspaceRepresenter,
  embedded: true)

  def workspaces
    collect
  end
end
