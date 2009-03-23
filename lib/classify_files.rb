require 'rush'                                            

module Rush::Ext
  
  module FileClassification
    
    def self.rush_dir(path_or_dir)
      return path_or_dir if path_or_dir.instance_of?(Rush::Dir)
      Rush::Dir.new(path_or_dir)
    end  
    
    def self.registrar
      @r ||= Registrar.new
    end
    
    def self.subclass_rush_file(name, &method_def_block)
      c = Class.new(Rush::File, &method_def_block)
      c.classification_name = name    
      c
    end
    
    ##
    #
    class Classification
      include Comparable
      attr_accessor :name, :dir
      def initialize(dir, name='default', &method_def_block)
        @name = name
        @dir =  FileClassification::rush_dir(dir)
      end               
      
      def applies?(filepath)
        puts filepath                  
        puts @dir
        @dir.entries.include?(filepath)
      end
      alias :on? :applies?                          
      

      
      def <=>(other)                                             
        self.to_s <=> other.to_s
      end                                                           
      
      def to_s() name  end
      
      def inspect
        "<'#@name': #{dir.to_s}>"  
      end
        
    end
         
    
    ##
    #
    class Registrar
      attr_accessor :classifications
      def initialize()
        clear!
      end            

      def clear!
        @classifications = []
      end
            
      def register(dir, name=nil, &method_def_block)  
        dir = FileClassification::rush_dir(dir)     
        name ||= singularized_working_dir(dir)
        @classifications << Classification.new(dir, name, &method_def_block)
      end                      
      
      def classifications_for(file)
        @classifications.find_all {|classify| classify.applies?(file)}
      end
      
      def classification_names
        @classifications.map {|classify| classify.name}
      end
      
      private
      def singularized_working_dir(dir)    
        dir.to_s.split('/').last.chomp('s')      
      end
    end
    
    # Globaly registered classifications:
    Registered = Registrar.new             
  end
end   

     

class Rush::File
  attr_writer :classification_registrar
  def classification_registrar
    @classification_registrar || Rush::Ext::FileClassification.registrar
  end
  
  def registered_classifications
    $foo
  end
  
  def classified?
    registered_classifications.include? self.path
    true
  end            
                     
  def method_missing(meth, *args, &blk)
    r = classification_registrar
    puts "!! #{self.to_s}" 
    puts self.read                    
    puts r.classification_names
    # puts r.classifications_for(self)
    
  end

  class <<self                        
    attr_writer :classification_name
    def classification_name
      @classification_name || "default"
    end
  end
end
