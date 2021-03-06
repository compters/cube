require 'savon'
require 'bigdecimal'

require_relative 'olap_result'

HTTPI.log = false

module XMLA

  class Cube
    attr_reader :query, :catalog

    def Cube.execute(query, withHeaders = true, catalog = XMLA.catalog)
      OlapResult.new(Cube.new(query, catalog).as_table(withHeaders))
    end

    def Cube.execute_scalar(query, withHeaders = true, catalog = XMLA.catalog)
      BigDecimal.new Cube.new(query, catalog).as_table(withHeaders)[0]
    end

    def as_table (withHeaders = true)
      return [table(withHeaders)] if y_size == 0
      table(withHeaders).reduce([]) { |result, row| result << row.flatten }
    end

    private

    #header and rows
    def table (withHeaders = true)
      if (header.size == 1 && y_size == 0)
        cell_data[0]
      else
        (0...y_axe.size).reduce(withHeaders ? header : []) do |result, j| 
          result << ( (withHeaders ? y_axe[j] : []) + (0...x_size).map { |i| cell_data[(j * x_axe.size) + i] }) 
        end
      end
    end

    def header
      [ ( (0..y_size - 1).reduce([]) { |header| header << '' } << x_axe).flatten ]
    end

    def axes
      axes = all_axes.select { |axe| axe[:@name] != "SlicerAxis" }
      @axes ||= axes.reduce([]) do |result, axe|
        result << tuple(axe).reduce([]) { |y, member|
          data = (member[0] == :member) ? member[1] : member[:member]
          if ( data.class == Hash || data.size == 1 )
            y << [(data[:caption] || "").strip].flatten 
          else
            y << data.select { |item_data| item_data.class == Hash }.reduce([]) do |z,item_data| 
              z << (item_data[:caption] || "").strip 
            end
          end
        }
      end
    end

    def initialize(query, catalog)
      @query = query
      @catalog = catalog
      @response = get_response
      self
    end

    def get_response
      client = Savon.client do
        wsdl File.expand_path("../../wsdl/xmla.xml", __FILE__)
        endpoint XMLA.endpoint
        basic_auth [XMLA.username, XMLA.password]
        log_level XMLA.log_level if XMLA.log_level
        log XMLA.log
        (proxy XMLA.proxy) unless XMLA.proxy.nil?
        (ssl_verify_mode :none) if XMLA.disable_ssl_verify
        convert_request_keys_to :camelcase # Required for SqlServer
      end

      cmd = { Command: { Statement: query },  
                                Properties: { PropertyList: {
                                    Catalog: catalog,
                                    Format: "Multidimensional",
                                    AxisFormat: "TupleFormat" } 
                                }
                              }
      # Need the xmlns attribute here or SqlServer throws an error
      @response = client.call(:execute, message: cmd, :attributes => {:xmlns => "urn:schemas-microsoft-com:xml-analysis" })

    end

    #cleanup table so items don't repeat (if they are same)
    def clean_table(table, number_of_colums)
      above_row = []
      #filter if they are not last column, and they are same as the item on the row above
      table.reduce([]) { |result, row|
        result <<  row.each_with_index.map do |item,i|
          if i == number_of_colums
            item 
          else
            item == above_row[i] ? '' : item 
          end
        end
        above_row = row
        result
      }
    end

    def cell_data
      cell_data = @response.to_hash[:execute_response][:return][:root][:cell_data]
      return [""] if cell_data.nil? 
      vals = cell_data[:cell]
      if vals.kind_of?(Hash)
        vals = [vals]
      end
      @data ||= Hash[vals.collect { |v| [Integer(v[:@cell_ordinal]), v[:value]] }] 
    end

    def tuple axe 
      axe[:tuples].nil? ? [] : axe[:tuples][:tuple]
    end
    
    def all_axes
      @response.to_hash[:execute_response][:return][:root][:axes][:axis]
    end
    
    def x_axe 
      @x_axe ||= axes[0] 
    end
    
    def y_axe
      @y_axe ||= axes[1]
    end
    
    def y_size 
      (y_axe.nil? || y_axe[0].nil?) ? 0 : y_axe[0].size
    end
    
    def x_size
      x_axe.size
    end
  end
end


