Extend the available methods of a Rush::File object based on its name, location, etc.  When an unknown method is called on a Rush::File, classy_files will find any classifications for that file with that method and mix it in to the file object.  E.g:

    classify_files 'markdown', :ext => 'md' do
      def to_html
        require 'maruku'
        Maruku.new(contents).to_html
      end
    end

Will grant files that end in `.md` a classification of `markdown`, and the `to_html()` will become available on them.  Besides basing the classification on the filename, you can base it's directory location as well:

    # delaration syntax:
    classify_files 'note', :in => 'notes/'
    classify_files 'markdown', :ext => 'md'
    classify_files 'video', :filename => /^ø/
    classify_files 'large', :if => lambda {|file| file.size > 1.mb}

    # default classification name as unpluralized form of dir:
    classify_files :in => 'notes/'
                         
    # add methods:                              
    classify_files :in => 'notes/' do   
      def title() name.upcase end
    end

    # subclassify (TODO):
    classify_files 'video', :subclass_of => 'note', :filename => /^ø/ do
      def run_time 
        '43 minutes'
      end      
  
      def title 
        'video' + super.title 
      end
    end
