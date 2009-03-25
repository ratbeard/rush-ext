`FileClassification` lets you extend the methods available on a Rush::File, based on declarations you provide.  This is simmilar to the ~/.rush/commands file, except more fine grained as you can choose which files will get which methods.  I needed the ability to generate a title based on if a file was a blog post or a note file, so I over-engineered and wrote this extension to add polymorphic behavior to files in Rush.

For example, all markdown files will get a handy helper from this:

    classify_files 'markdown', :ext => %w{ md mdtext markdown } do
      def to_html
        require 'maruku'
        Maruku.new(contents).to_html
      end
    end

If you want to add special powers to files under the directories `~/notes` and `~/posts`:

    classify_files 'note', :in => '~/notes/' do
      def title
        name.upcase
      end
    end
    
    classify_files :in => '~/posts/' do
      def title
        "I'll be given a default classification name based on my dir"
      end       
    end
    
Now you can do:

    

Syntax:

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
