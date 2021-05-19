module AppMap
  module Depends
    module Util
      extend self

      def normalize_path(path, pwd: Dir.pwd)
        normalize_path_fn(pwd).(path)
      end

      def normalize_paths(paths, pwd: Dir.pwd)
        paths.map(&normalize_path_fn(pwd))
      end

      private

      def normalize_path_fn(pwd)
        lambda do |path|
          path = path[pwd.length + 1..-1] if path.index(pwd) == 0
          path.split(':')[0]
        end  
      end
    end
  end
end
