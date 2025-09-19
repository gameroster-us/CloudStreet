module CSLogger

	class << self

		def logger
			(Sidekiq.server?) ? Sidekiq.logger  : Rails.logger
		end

		def info(message=nil)
			# CS_logger = init_logger
			logger.info(message) if message
		end

		def debug(message=nil)
			logger.debug(message) if message
		end

		def error(message=nil)
			logger.error(message) if message
		end

		def warn(message=nil)
			logger.warn(message) if message
		end

		def fatal(message=nil)
			logger.fatal(message) if message
		end
	end
	
end