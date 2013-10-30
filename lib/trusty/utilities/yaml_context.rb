module Trusty
  module Utilities
    class YamlContext
      def self.render(content, &block)
        new(content, &block).render
      end
      
      def initialize(content, &block)
        @content = content
        
        yield(self) if block_given?
      end
      
      def render
        YAML.load ERB.new(@content).result(binding)
      end
    end
  end
end