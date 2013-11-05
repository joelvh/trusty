require 'iron_mq'
require 'trusty/errors/exception_handlers'

module Trusty
  module IronIo
    class QueueProcessor
      include ::Trusty::Errors::ExceptionHandlers
      
      # helper method forwards to "run" instance method
      def self.run(queue_name, *args, &block)
        new(queue_name).run(*args, &block)
      end
      
      attr_reader :queue_name, :client
      
      def initialize(queue_name)
        @queue_name = queue_name
        @client     = IronMQ::Client.new(:token => ENV['IRON_TOKEN'], :project_id => ENV['IRON_PROJECT_ID'])
      end
      
      def default_options
        { :timeout => 30, :break_if_nil => true }
      end
      
      def queue
        @queue ||= client.queue(queue_name)
      end
      
      def run(options = {}, &block)
        options = default_options.merge(options)
        
        queue.poll(options) do |message|#, :break_if_nil => true do |message|
          
          # parse body for better data formatting
          begin
            body = JSON.parse message.body
          rescue JSON::ParserError => ex
            body = message.body
          end
          
          try_with_data :message_id => message.id, :body => body do
            block.call(message, queue)
          end
        end
      end
      
      def webhook_url
        url_template = 'https://mq-aws-us-east-1.iron.io/1/projects/%{project_id}/queues/%{queue_name}/messages/webhook?oauth=%{token}'
        
        url_template % {
          project_id: ENV['IRON_TOKEN'],
          token: ENV['IRON_PROJECT_ID'],
          queue_name: queue_name
        }
      end
      
    end
  end
end
