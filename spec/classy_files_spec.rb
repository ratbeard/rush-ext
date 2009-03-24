require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'classy_files.rb')

# Helpers for pointing at fixture data directories, /notes and /posts,
# found right here underneath the spec dir
module SampleHelpers
  def path_to(dir_name)
    File.expand_path(File.join(File.dirname(__FILE__), dir_name))
  end                                       
    
  def sample_note
    Rush::Dir.new(path_to('notes')).contents.first  
  end
  
  def sample_post
    Rush::Dir.new(path_to('posts')).contents.first  
  end                                
end                          

      
                             
describe "classifying files" do
  include SampleHelpers                      
  include ClassyFiles
  after :each do
    ClassyFiles::Registered.clear
  end                                 
  
  it "stores registered classifications globally" do
    # given
    classify_files 'note', :in => path_to('notes')
    classify_files 'post', :in => path_to('posts')
    # then                                     
    ClassyFiles::Registered.should == ['note', 'post']
  end
  
  it "adds `classifications` method to Rush::File" do
    # given
    classify_files 'note', :in => path_to('notes')
    # then                                  
    sample_note.classifications.should have(1).thing
    sample_note.should be_classified('note')    
    sample_note.should_not be_classified('post')    
  end                 
  
  it "allows adding methods" do
    # given
    classify_files :in => path_to('notes') do
      def intro() lines.first end
    end
    # then
    ClassyFiles::Registered.first.added_methods.should == ['intro']
    sample_note.intro.should == 'hi'
  end
  
  it "dispatches added methods to the correct classification" do
    # given
    classify_files :in => path_to('notes') do
      def intro() lines.first end
    end
    classify_files :in => path_to('posts') do
      def intro() "blah" end
    end
    # then
    sample_note.intro.should == 'hi'
    sample_post.intro.should == 'blah'
  end
  

  
  
  describe "based on its filename" do
    it "through the file extension with the :ext option" do
      # given
      classify_files 'markdown', :ext => 'md' do
        def to_html
          require 'maruku'
          Maruku.new(contents).to_html
        end
      end 
      # then
      sample_note.to_html.should == "<p>hi <em>ho</em></p>"
    end        
    
    it "through a filename regex with the :filename option" do
      # given
      classify_files 'blog_post', :filename => /_post/ do
        def publish!() 200 end
      end 
      # then                   
      post = Rush::Dir.new(path_to('posts'))['second_post.rb']
      post.publish!.should == 200
    end
  end
  
  
  describe "based on its location" do
    it "return correct classification for a file based on its location" do
      # given
      classify_files 'note', :in => path_to('notes')
      classify_files 'post', :in => path_to('posts')
      # then                                     
      sample_note.classifications.should == ['note']
      sample_post.classifications.should == ['post']
    end   

    it "defaults classification name to the unpluralized dir name" do
      # given
      classify_files :in => path_to('notes')
      # then
      sample_note.classifications.should == ['note']        
    end
    
    xit "takes precedence over filename declarations"
  end
end
