require 'rspreadsheet/cell'
require 'rspreadsheet/xml_tied'


module Rspreadsheet

# Represents a row in a spreadsheet which has coordinates, contains value, formula and can be formated.
# You can get this object like this (suppose that @worksheet contains {Rspreadsheet::Worksheet} object)
#
#     @row = @worksheet.row(5)
#
# Mostly you will this object to access row cells values
#
#     @row[2]           # identical to @worksheet[5,2] or @row.cells(2).value
#
# or directly row `Cell` objects
#
#     @row.cell(2)     # => identical to @worksheet.rows(5).cells(2)
#
# You can use it to manipulate rows
#
#     @row.add_row_above   # adds empty row above
#     @row.delete          # deletes row 
#
# and shifts all other rows down/up appropriatelly.

class Row < XMLTiedItem
  include XMLTiedArray
  ## @return [Worksheet] worksheet which contains the row
  # @!attribute [r] worksheet
  attr_reader :worksheet
  ## @return [Integer] row index of the row
  # @!attribute [r] rowi
  attr_reader :rowi 
    
  def initialize(aworksheet,arowi)
    @worksheet = aworksheet
    @rowi = arowi
    @itemcache = Hash.new  #TODO: move to module XMLTiedArray
  end
  
  def xmlnode; parent.find_my_subnode_respect_repeated(index, xml_options)  end
    
 # @!group Syntactic sugar
  def cells(*params); subitems(*params) end
  alias :cell :cells
  
  ## @return [String or Float or Date] value of the cell
  # @param coli [Integer] colum index of the cell 
  # returns value of the cell at column `coli`. 
  #  
  #     @row = @worksheet.rows(5)     # with cells containing names of months
  #     @row[1]                       # => "January" 
  #     @row.cells(2).value           # => "February"  
  #     @row[1].class                 # => String
  def [](coli); cells(coli).value end
  # @param avalue [Array] 
  # sets value of cell in column `coli`
  def []=(coli,avalue); cells(coli).value=avalue end
  # @param avalue [Array] array with values 
  # sets values of cells of row to values from `avalue`. *Attention*: it deletes the rest of row
  #  
  #     @row = @worksheet.rows(5)     
  #     @row.values = ["January", "Feb", nil, 4] # =>  | January | Feb |  | 4 |
  #     @row[2] = "foo")                         # =>  | January | foo |  | 4 |
  def cellvalues=(avalue)
    self.truncate
    avalue.each_with_index{ |val,i| self[i+1] = val }
  end
  ## @return [Array
  # return array of cell values 
  # 
  #     @worksheet[3,3] = "text"
  #     @worksheet[3,1] = 123
  #     @worksheet.rows(3).cellvalues            # => [123, nil, "text"]
  def cellvalues
    cells.collect{|c| c.value}
  end
 # @!endgroup
  
 # @!group Other methods
  def style_name=(value); 
    detach_if_needed
    Tools.set_ns_attribute(xmlnode,'table','style-name',value)
  end
  def nonemptycells
    nonemptycellsindexes.collect{ |index| subitem(index) }
  end
  def nonemptycellsindexes
    myxmlnode = xmlnode
    if myxmlnode.nil?
      []
    else
      @worksheet.find_nonempty_subnode_indexes(myxmlnode, {:xml_items_node_name => 'table-cell', :xml_repeated_attribute => 'number-columns-repeated'})
    end
  end
  alias :used_range :range
  # Inserts row above itself (and shifts itself and all following rows down)
  def add_row_above
    parent.add_row_above(rowi)
  end
  
 # @!group Private methods, which should not be called directly
  # @private
  # shifts internal represetation of row by diff. This should not be called directly
  # by user, it is only used by XMLTiedArray as hook when shifting around rows
  def _shift_by(diff)
    super
    @itemcache.each_value{ |cell| cell.set_rowi(@rowi) }
  end
  
 private
  # @!group XMLTiedArray related methods
  def subitem_xml_options; {:xml_items_node_name => 'table-cell', :xml_repeated_attribute => 'number-columns-repeated'} end
  def prepare_subitem(coli); Cell.new(@worksheet,@rowi,coli) end
  # @!group XMLTiedItem related methods and extensions
  def xml_options; {:xml_items_node_name => 'table-row', :xml_repeated_attribute => 'number-rows-repeated'} end
  def parent; @worksheet end                
  def index; @rowi end                       
  def set_index(value); @rowi=value end      
end

end