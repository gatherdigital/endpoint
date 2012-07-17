module Endpoint
  module Soap

    class RequestBuilder

      # Options:
      #
      #   :compact - boolean that directs the builder to produce a single line
      #   xml document. Defaults to false so that pretty XML is produced.
      #
      #   :namespaces - A Hash of options for the document namespaces:
      #     :env - An optional SOAP element namespace item to be used when
      #     producing the Envelope, Header, and Body elements (i.e.
      #     "<env:Envelope>"). This is unused when :all is provided.
      #
      #     :add - An optional Array of namespace items to add to the default,
      #     normal SOAP namespaces. This is unused when :all is provided.
      #
      #     :all - An optional Array of all the namespace items to be used. It's
      #     presence causes the requirement of the envindex option.
      #
      #     :envindex - The index in the Array provided to :all which indicates
      #     the SOAP element namespace.
      #
      # Ultimately, an Array of namespaces is used to add to the document
      # Envelope element attributes. Each item is an Array itself of the form
      # [xmlns_name, value].  If you need to declare your namespace directly on
      # your 'operation' element (inside the Body element), it need not be
      # added here.
      def initialize(options = {})
        @options = options

        nsopts = options[:namespaces] || {}
        if @namespaces = nsopts[:all]
          if nsopts[:add] then raise ':all option was provided for namespaces. :add option must not be provided.' end
          if nsopts[:env] then raise ':all option was provided for namespaces. :env option must not be provided.' end
          envindex = nsopts[:envindex]
          unless envindex then raise ':all option was provided for namespaces. :envindex must also be provided.' end
          @envns = @namespaces[envindex][0]
        else
          @namespaces = [
            %w(xsi http://www.w3.org/2001/XMLSchema-instance),
            %w(xsd http://www.w3.org/2001/XMLSchema),
            nsopts[:env] || %w(env http://schemas.xmlsoap.org/soap/envelope/)
          ]
          @namespaces += nsopts[:add] if nsopts[:add]
          @envns = @namespaces[2][0]
        end
      end

      def render(options)
        RenderContext.new(@namespaces, @envns, @options[:compact]).render(options)
      end
    end

    class RenderContext
      attr_reader :compact, :namespaces, :envns

      def initialize(namespaces, envns, compact = false)
        @namespaces, @envns, @compact = namespaces, envns, compact
      end

      def install_namespaces(envelope_node)
        namespaces.each do |name, uri|
          ns = envelope_node.add_namespace name, uri
          envelope_node.namespace = ns if name == envns
        end
      end

      def render(options)
        header, body = options[:header], options[:body]
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.Envelope {
            install_namespaces xml.parent
            if header
              xml[envns].Header { header.call xml }
            end
            if body.respond_to?(:call)
              xml[envns].Body { body.call xml }
            else
              xml[envns].Body body
            end
          }
        end
        output = builder.to_xml(indent:(compact ? 0 : 2))
        compact ? output.gsub(/\n/, '') : output
      end
    end

  end
end
