require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'

describe "Index definition" do

  let(:migration) { ::ActiveRecord::Migration }

  context "when index is multicolumn" do
    before(:each) do
      migration.suppress_messages do
        migration.execute "CREATE INDEX users_login_index ON users (login, deleted_at)"
      end
      User.reset_column_information
      @index = index_definition(%w[login deleted_at])
    end

    after(:each) do
      migration.suppress_messages do
        migration.remove_index :users, :name => 'users_login_index'
      end
    end

    it "is included in User.indexes" do
      User.indexes.select { |index| index.columns == %w[login deleted_at] }.should have(1).item
    end

  end

  if ::ActiveRecord::Base.connection.class.include?(RedhillonrailsCore::ActiveRecord::ConnectionAdapters::PostgresqlAdapter)

    context "when case insensitive is added" do

      before(:each) do
        migration.suppress_messages do
          migration.execute "CREATE INDEX users_login_index ON users(LOWER(login))"
        end
        User.reset_column_information
        @index = User.indexes.detect { |i| i.expression =~ /lower\(\(login\)::text\)/i }
      end

      after(:each) do
        migration.suppress_messages do
          migration.remove_index :users, :name => 'users_login_index'
        end
      end

      it "is included in User.indexes" do
        @index.should_not be_nil
      end

      it "is not case_sensitive" do
        @index.should_not be_case_sensitive
      end

      it "defines expression" do
        @index.expression.should == "lower((login)::text)"
      end

      it "doesn't define conditions" do
        @index.conditions.should be_nil
      end

    end


    context "when index is partial and column is not downcased" do
      before(:each) do
        migration.suppress_messages do
          migration.execute "CREATE INDEX users_login_index ON users(login) WHERE deleted_at IS NULL"
        end
        User.reset_column_information
        @index = index_definition("login")
      end

      after(:each) do
        migration.suppress_messages do
          migration.remove_index :users, :name => 'users_login_index'
        end
      end

      it "is included in User.indexes" do
        User.indexes.select { |index| index.columns == ["login"] }.should have(1).item
      end

      it "is case_sensitive" do
        @index.should be_case_sensitive
      end

      it "doesn't define expression" do
        @index.expression.should be_nil
      end

      it "defines conditions" do
        @index.conditions.should == "(deleted_at IS NULL)"
      end

    end

    context "when index contains expression" do
      before(:each) do
        migration.suppress_messages do
          migration.execute "CREATE INDEX users_login_index ON users (extract(EPOCH from deleted_at)) WHERE deleted_at IS NULL"
        end
        User.reset_column_information
        @index = User.indexes.detect { |i| i.expression.present? }
      end

      after(:each) do
        migration.suppress_messages do
          migration.remove_index :users, :name => 'users_login_index'
        end
      end

      it "exists" do
        @index.should_not be_nil
      end

      it "doesnt have columns defined" do
        @index.columns.should be_empty
      end

      it "is case_sensitive" do
        @index.should be_case_sensitive
      end

      it "defines expression" do
        @index.expression.should == "date_part('epoch'::text, deleted_at)"
      end

      it "defines conditions" do
        @index.conditions.should == "(deleted_at IS NULL)"
      end

    end

  end # of postgresql specific examples

  protected
  def index_definition(column_names)
    User.indexes.detect { |index| index.columns == Array(column_names) }
  end


end
