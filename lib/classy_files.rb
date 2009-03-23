require 'rush'                                            

module ClassyFiles 

  # register new file classifications 
  def classify_files(*args, &method_def_block)
    Registered << FileKind.new(*args, &method_def_block)
  end
                           
  # Global file classification registrar
  Registered = []
  def Registered.for(file)
    matches = find_all {|kind| kind.applies_to?(file) }
  end
  
  # Encapsulate a classification
  # name, conditions, and methods to add
  class FileKind 
    include Comparable
    attr_accessor :name, :methods_mixin
    
    def initialize(*args, &method_def_block)           
      opts = args.pop                
      @dir = opts[:in]  
      @name = args.first || generate_name
      @methods_mixin = Module.new(&method_def_block)
    end                                                 
                                            
    def generate_name
      @dir.to_s.split('/').last.chomp('s')      
    end
    
    def rush_dir
      Rush::Dir.new(@dir) 
    end
    
    def applies_to?(file)
      rush_dir.entries.include?(file)
    end
    
    def <=>(other)
      if other.kind_of? String
        self.name <=> other
      else
        self <=> other
      end
    end           
    
    def to_s 
      name
    end
    
    def inspect
      to_s
    end
    
    def added_methods
      @methods_mixin.instance_methods      
    end
    
    def adds_method?(meth)
      added_methods.include?(meth.to_s)
    end
  end
end


module Rush
  class File
    def classifications
      ClassyFiles::Registered.for(self)
    end
    
    def classified?(name)
      classifications.include? name
    end                          

    # Find first classification that adds the called method and 
    # mix it in to self and call the method
    def method_missing(meth, *args, &blk)
      k = classifications.find {|kind| kind.adds_method?(meth)}
      if k.nil? 
        super
      else
        self.extend(k.methods_mixin) 
        self.send meth, *args, &blk
      end
    end
  end
end