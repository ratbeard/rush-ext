require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'classify_files.rb')

def example_path
  File.expand_path(File.dirname(__FILE__))
end

def example
  Rush[example_path + '/']
end                                       

def example_note
  example['notes/'].contents.first  
end

def example_post
  example['posts/'].contents.first  
end                  

      

module Rush::Ext::FileClassification 
  
describe "Subclassing Rush::File" do
  it "through the FileClassification::subclass_rush_file method" do
    pic_class = Rush::Ext::FileClassification::subclass_rush_file('pic')
    pic_class.new('~').should be_kind_of(Rush::File)
  end
end                         

describe "a file classication object" do
  it "should only include files in the given path" do
    @posts_class = Classification.new(example_path + '/posts/', 'post')
    @posts_class.should be_on(example_post)
    @posts_class.should_not be_on(example_note)
  end
  it "should be == to a string of the classification name" do
    @classify = Classification.new('~', 'post')      
    @classify.should == 'post'
  end
end  

describe "registering classifications" do
  it "stores registered classifications, accepting paths or rush objects" do
    # given
    r = Registrar.new
    r.register('~/laugh','funny_vids')              
    r.register(Rush['~/docs/'], 'papers')
    # then
    r.classifications.should have(2).things
    r.classifications.should include('funny_vids')
    r.classifications.should include('papers')
  end
  
  it "should allow clearing the classifications" do
    # given
    r = Registrar.new
    r.register('~/laugh','funny_vids')
    # when
    r.clear!
    # then
    r.classifications.should have(0).things      
  end                                               
  
  it "should default the classification name to the un-pluralized dir name" do
    # given
    r = Registrar.new
    r.register('~/video')
    r.register('/etc/links')
    # then
    r.classification_names.should == ['video', 'link']
  end
  
  it "should return a matched classification" do
    # given
    r = Registrar.new
    r.register(example['notes/'])
    # then
    r.classifications_for(example_note).should have(1).things      
    r.classifications_for(example_note).should include('note')      
    r.classifications_for(example_post).should have(0).things
  end
end  

describe "adding methods" do
  it "should " do
    # given
    r = Registrar.new
    r.register(example['notes/']) do
      def second_line 
        puts "<<<"
        lines[1]
      end
    end                                     
    # when       
    example_note.classification_registrar = r
    # then
    example_note.second_line.should == "ho"
  end
end

describe "registering file classifications globally w/ Rush" do
  after :each do
    Rush::Ext::FileClassification::Registered.clear!
  end                                             
  
  it "done in Rush::Ext::FileClassification::Registered global" do
    lambda {
      Registered.register('~/recipes')
    }.should change(Registered.classifications, :length).from(0).to(1)
  end                    
  
  describe "and adding methods" do
    it "should " do
      
    end
  end
     
end
end                             
