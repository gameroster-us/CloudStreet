module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeVpcs < Fog::Parsers::Base
          def reset
            @context = []
            @response = {}
            @vpcSet = []
            initialize_vpc
          end

          def initialize_vpc
            @cidrBlockAssociationSet = []
            @ipv6CidrBlockAssociationSet = []
            @tagSet = {}
            @vpc = {"tagSet" => {},"cidrBlockAssociationSet" => [], "ipv6CidrBlockAssociationSet" => []}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            # CSLogger.info "vpc-----#{@vpc}"
            #--------------set ipv4 block----------

            if name == "item" && @context.last[:key] == "cidrBlockState"
              cidrBlock = {}
              (1..4).each {
                element  = @context.pop
                next if element[:key] == "cidrBlockState"
                if element[:key] == "state"
                  cidrBlock["cidrBlockState"] = {element[:key] => element[:value]}
                else
                  cidrBlock[element[:key]] = element[:value]
                end
              }
              @cidrBlockAssociationSet << cidrBlock
              return 
            end

            if name == "cidrBlockAssociationSet"
              @vpc["cidrBlockAssociationSet"] = @cidrBlockAssociationSet
              return
            end

            #--------------set ipv6 block----------

            if name == "item" && @context.last[:key] == "ipv6CidrBlockState"
              ipv6CidrBlock = {}
              (1..4).each {
                element  = @context.pop
                next if element[:key] == "Ipv6CidrBlockState"
                if element[:key] == "state"
                  ipv6CidrBlock["Ipv6CidrBlockState"] = {element[:key] => element[:value]}
                else
                  ipv6CidrBlock[element[:key]] = element[:value]
                end
              }
              @ipv6CidrBlockAssociationSet << ipv6CidrBlock
              return 
            end

            if name == "ipv6CidrBlockAssociationSet"
              @vpc["ipv6CidrBlockAssociationSet"] = @ipv6CidrBlockAssociationSet
              return
            end

            #--------------set tag----------
            if name == "item" && @context.last[:key] == "value"
              tag_key = nil
              tag_value = nil
              (1..2).each {
                element  = @context.pop
                case element[:key]
                when "key"
                  tag_key = element[:value]
                when "value"
                  tag_value = element[:value]
                end
              }
               @tagSet[tag_key] = tag_value
              return
            end

            if name == "tagSet"
              @vpc["tagSet"] = @tagSet
              return
            end

            #--------------set vpc----------
            if name == "item" && @context.last[:key] == "isDefault"

              begin
                element = @context.pop
                @vpc[element[:key]] = element[:value]
              end until @context.last[:key] == "requestId"
              @vpcSet << @vpc
              initialize_vpc
              return
            end

            if name == "vpcSet"
              @response["vpcSet"] = @vpcSet
              @vpcSet = []
              return
            end

            if name == "DescribeVpcsResponse"
              @context.each do |element|
                @response[element[:key]] = element[:value]
              end
              return
            end

            if value && !value.empty?
              @context.push({:key => name, :value => value.squish})
            else
              @context.push({:key => name, :value => nil})
            end

          end
        end
      end
    end
  end
end
