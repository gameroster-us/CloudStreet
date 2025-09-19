class MachineImageGroup < ApplicationRecord
  belongs_to :region
  has_many :machine_images
  has_many :organisation_images

  scope :matching, -> (image){ where({
        virtualization_type: image.virtualization_type,
        image_owner_alias: image.image_owner_alias,
        root_device_type: image.root_device_type,
        image_owner_id: image.image_owner_id,
        architecture: image.architecture,
        image_type: image.image_type,
        is_public: image.is_public,
        region_id: image.region_id,
        platform: image.platform
      })}

  def latest_machine_image
    machine_images.sort_by(&:created_at).last
  end

  class << self

    def find_or_create_best_matching_group(machine_image, groups)
      group = nil
      if machine_image.group.present?
        group = machine_image.group
      else
        unique_group_id = gen_group_key(machine_image, groups)
        group = groups.detect{|image_group| image_group.name.eql?(unique_group_id)}
        unless group
          image_name = machine_image.image_location.split("amazon/").last
          group = MachineImageGroup.new(name: unique_group_id, match_key: image_name, region: machine_image.region)
          group.virtualization_type = machine_image.virtualization_type
          group.image_owner_alias = machine_image.image_owner_alias
          group.root_device_type = machine_image.root_device_type
          group.image_owner_id = machine_image.image_owner_id
          group.architecture = machine_image.architecture
          group.image_type = machine_image.image_type
          group.is_public = machine_image.is_public
          group.region_id = machine_image.region_id
          group.platform = machine_image.platform
          group.save
          groups << group
        end
      end
      group
    end

    def gen_group_key(image, groups)
      matched_architecture = image.image_location.split("amazon/").last.match(/(i386-ebs|i386-gp22|x86-64-gp2|x86-64-ebs)/)
      group_name = find_closest_matching_group_name(image, groups)
      Digest::MD5.hexdigest(Marshal::dump({
        matched: matched_architecture ? matched_architecture.captures.first : nil,
        virtualization_type: image.virtualization_type,
        image_owner_alias: image.image_owner_alias,
        root_device_type: image.root_device_type,
        image_owner_id: image.image_owner_id,
        architecture: image.architecture,
        image_type: image.image_type,
        is_public: image.is_public,
        region_id: image.region_id,
        platform: image.platform,
        group_match: group_name
      }))
    end

    def find_closest_matching_group_name(image, groups)
      image_name = image.image_location.split("amazon/").last
      unless groups.empty?
        closest_matching_group = groups.max_by do |group|
          group.match_key.similar(image_name)
        end
        percentage_similarity = closest_matching_group.match_key.similar(image_name)
        if(percentage_similarity && percentage_similarity > 97)
          return closest_matching_group.match_key
        end
      end
      return image_name
    end
  end
end
