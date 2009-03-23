require 'rush'                                            

module ClassyFiles 

  def classify_files(*args)
    Registered << FileKind.new(*args)
  end
                           
  ## Registry:
  Registered = []
  def Registered.for(file)
    matches = find_all {|kind| kind.applies_to?(file) }
  end
                                               
  def Registered.names
    map {|kind| kind.name }
  end         
  
  class FileKind 
    include Comparable
    attr_accessor :name    
    def initialize(*args)           
      opts = args.pop                
      @dir = opts[:in]  
      @name = args.empty? ?  generate_name :  args.first
    end                                                 
    
    def generate_name
      @dir.to_s.split('/').last.chomp('s')      
    end
    
    def rush_dir() Rush::Dir.new(@dir) end
    
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
  end
  
end


module Rush
  class File
    def classified?(name)
      classifications.include? name
    end                          
    
    def classifications
      ClassyFiles::Registered.for(self)
    end
  end
end