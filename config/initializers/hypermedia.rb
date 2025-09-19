Roar::Hypermedia.module_eval do
  private
  def run_link_block(block, options)
    # We need all options come from cotroller, so passing all
    instance_exec(options, &block)
  end
end
