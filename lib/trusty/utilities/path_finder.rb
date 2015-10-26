module Trusty
  module Utilities
    module PathFinder
      module ClassMethods
        def find(filename, paths = [])
          if File.file?(filename)
            filename
          elsif root = Array(paths).find{|path| File.file?(File.join(path, filename))}
            File.join(root, filename)
          end
        end
      end
      
      extend ClassMethods
    end
  end
end