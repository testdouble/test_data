module TestData
  module CustomLoaders
    class AbstractBase
      def name
        raise Error.new("#name must be defined by CustomLoader subclass")
      end

      def load_requested(**options)
      end

      def loaded?(**options)
        # Check to see if the requested data is already loaded (if possible and
        # detectable)
        #
        # Return true to prevent #load from being called, potentially avoiding an
        # expensive operation
        false
      end

      def load(**options)
        raise Error.new("#load must be defined by CustomLoader subclass")
      end
    end
  end
end
