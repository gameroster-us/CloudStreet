module Rswag::Ui::CSP
  def call env
    _, headers, _ = response = super
    headers['Content-Security-Policy'] = <<~POLICY.gsub "\n", ' '
      connect-src *; 
    POLICY
    response
  end
end

Rswag::Ui::Middleware.prepend Rswag::Ui::CSP