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
    not_md = Rush::Dir.new(path_to('posts'))['second_post.rb']
    lambda { not_md.to_html }.should raise_error
  end        
  
  it "through a filename regex with the :filename option" do
    # given
    classify_files 'blog_post', :filename => /_post/ do
      def publish!() 200 end
    end 
    # then                   
    post = Rush::Dir.new(path_to('posts'))['second_post.rb']
    post.should be_classified 'blog_post'
    post.publish!.should == 200
    not_a_post = Rush::Dir.new(path_to('posts'))['first.md']
    not_a_post.should_not be_classified 'blog_post'
    lambda { not_a_post.publish! }.should raise_error
  end
  
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
    

end

describe "a file with multiple classifications" do
  include SampleHelpers                      
  include ClassyFiles
  
  before :each do
    classify_files 'post', :in => path_to('posts') do
      def face() 'im interesting' end
    end                 
            
    classify_files 'code', :ext => '.rb' do
      def face() '010110' end
    end                                    
    
    classify_files 'follow_up', :filename =~ /^(second|2)_/ do
      def face() 'getting back to you' end
    end                              
  end  
  
  after :each do
    ClassyFiles::Registered.clear
  end
                                     
  
  describe "dispatches methods to the highest priority classification " do
    it ":in restrictions have higher priority than :filename and :ext" do                                        
      # given
      classify_files
      # then
    end     
    
    it ":filename restrictions have higher priority than :ext" do
      # given
      # then
    end                                                          
    
    
    
  end
end