namespace :machine_image_loader do
	desc "Loads the machine images from sql dump for AMI"
  task load_machine_images: :environment do
    # MachineImageLoaderWorker.perform_async  
    MachineImageLoaderWorker.perform_at(20.minutes.from_now)
	end
end
