# copy and modify from https://github.com/AliyunContainerService/log-pilot/blob/master/assets/fluentd/plugins/out_aliyun_sls.rb

module Fluent

    class AliyunSlsOutput < BufferedOutput
        Plugin.register_output('aliyun_sls', self)

        config_param :project, :string, :default => nil
        config_param :region_endpoint, :string, :default => nil
        config_param :access_key_id, :string, :default => nil
        config_param :access_key_secret, :string, :default => nil
        config_param :ssl_verify, :bool, :default => false
        config_param :logstore, :string, :default => nil
        config_param :need_create_logstore, :bool, :default => false
        config_param :create_logstore_ttl, :integer, :default => 1
        config_param :create_logstore_shard_count, :integer, :default => 2

        def initialize
            super
            require "aliyun_sls_sdk/protobuf"
            require "aliyun_sls_sdk"
        end

        def configure(conf)
            super
        end


        def start
            super
        end

        def shutdown
            super
        end

        def format(tag, time, record)
            [tag, time, record].to_msgpack
        end

        def client
            @_sls_con ||= AliyunSlsSdk::LogClient.new(@region_endpoint, @access_key_id, @access_key_secret, @ssl_verify)
        end

        def createLogStore(logstore_name)
            retries = 2
            begin
                createLogStoreResp = client.create_logstore(@project, logstore_name, @create_logstore_ttl, @create_logstore_shard_count)
            rescue AliyunSlsSdk::LogException => e
                if e.errorCode == "LogStoreAlreadyExist"
                    log.warn "logstore #{logstore_name} already exist"
                else
                    raise
                end
            rescue => e
                if retries > 0
                    log.warn "Error caught when creating logs store: #{e}"
                    retries -= 1
                    retry
                end
            end
        end

        def getLogItem(record)
            contents = {}
            record.each { |k, v|
                contents[k] = v
            }
            AliyunSlsSdk::LogItem.new(nil, contents)
        end

        def write(chunk)
            log_itemlist = []
            chunk.each do |tag, time, record|
                log_itemlist << getLogItem(record)
            end

            log_itemlist.each_slice(4096) do |items|
                putLogRequest = AliyunSlsSdk::PutLogsRequest.new(@project, @logstore, nil, nil, items, nil, true)
                retries = 0
                begin
                    client.put_logs(putLogRequest)
                rescue  => e
                    if e.instance_of?(AliyunSlsSdk::LogException) && e.errorCode == "LogStoreNotExist" && @need_create_logstore
                        createLogStore(@logstore)
                        # wait up to 60 seconds to create the logstore
                        if retries < 3
                            retries += 1
                            sleep(10 * retries)
                            retry
                        end
                    else
                        log.warn "\tCaught in puts logs: #{e.message}"
                        if retries < 3
                            client.http.shutdown
                            @_sls_con = nil
                            retries += 1
                            sleep(1 * retries)
                            retry
                        end
                        log.error "Could not puts logs to aliyun sls: #{e.message}"
                    end
                end
            end
        end
        
    end
end