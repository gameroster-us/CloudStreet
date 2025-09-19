class SolrSearcher < CloudStreetService
	def self.search_service(search_query, account, tenant, &block)
    begin 
      account_id = account.id
      adapter_ids = tenant.adapters.normal_adapters.pluck(:id)
      # TODO- Add pagination- # paginate(:page => page || 1, :per_page => 15)
      search = Sunspot.search Service, Snapshot do
      	with :account_id, "#{account_id}"
        with(:adapter_id).any_of(adapter_ids) unless adapter_ids.blank?
        without(:state, ["directory", "template", "terminated"])
      	fulltext "#{search_query}"
      	group :search_object_id do
      		limit -1
      	end
        order_by(:object_type, :asc)
      end
      solr_search_result = []
      search.group(:search_object_id).groups.each do |group|
      	group_hash = {
      		search_object_id: group.value,
      		search_object_name: group.solr_docs[0]["search_object_name_ss"],
          object_type: group.solr_docs[0]["object_type_ss"],
      		services: group.hits
      	}
      	solr_search_result << group_hash
      end
      status Status, :success, solr_search_result, &block
      return solr_search_result
    rescue RSolr::Error::ConnectionRefused => e
      CSLogger.error "Unable to connect to solr #{e.class} : #{e.message} : #{e.backtrace}"
      status Status, :error, [], &block
      return []
    rescue Exception => e
      CSLogger.error "SolrSearcher.index_objects : #{e.class} : #{e.message} : #{e.backtrace}" 
      status Status, :error, [], &block
      return []  
    end
	end

  def self.index_objects(records_to_be_indexed)
    begin
      unless records_to_be_indexed.blank?
        response = Net::HTTP.get_response(URI.parse(Sunspot.config.solr.url+"/select?wt=json"))
        Sunspot.index(records_to_be_indexed) if response.kind_of? Net::HTTPSuccess
        #Sunspot.commit(true) # for soft commit
      end      
    rescue RSolr::Error::ConnectionRefused => e
      CSLogger.error "Unable to connect to solr #{e.class} : #{e.message} : #{e.backtrace}"
    rescue Exception => e
      CSLogger.error "SolrSearcher.index_objects : #{e.class} : #{e.message} : #{e.backtrace}"   
    end
  end

  def self.remove_objects_from_index(records_to_be_removed)
    begin
      Sunspot.remove(records_to_be_removed) unless records_to_be_removed.blank?
    rescue RSolr::Error::ConnectionRefused => e
      CSLogger.error "Unable to connect to solr #{e.class} : #{e.message} : #{e.backtrace}"
    rescue Exception => e
      CSLogger.error "SolrSearcher.remove_objects_from_index : #{e.class} : #{e.message} : #{e.backtrace}"   
    end
  end

  def self.remove_objects_by_id_from_index(klass, uuids_to_be_removed)
    begin
      Sunspot.remove_by_id!(klass, uuids_to_be_removed) if uuids_to_be_removed.present? && klass.present?
    rescue RSolr::Error::ConnectionRefused => e
      CSLogger.error "Unable to connect to solr #{e.class} : #{e.message} : #{e.backtrace}"
    rescue Exception => e
      CSLogger.error "SolrSearcher.remove_objects_by_id_from_index : #{e.class} : #{e.message} : #{e.backtrace}"   
    end
  end

  # Returns a hash with type as a key & value is array of uuids
  def self.prepare_data_hash_to_be_removed_by_id(objects_to_be_removed)
    objects_to_be_removed.present? ? (objects_to_be_removed.map{ |k, v| [k, (v.map{|obj| obj.id}) ]}.to_h) : {}
  end
end
