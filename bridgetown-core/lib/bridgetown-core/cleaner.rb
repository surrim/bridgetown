# frozen_string_literal: true

module Bridgetown
  # Handles the cleanup of a site's destination before it is built.
  class Cleaner
    HIDDEN_FILE_REGEX = %r!/\.{1,2}$!
    attr_reader :site

    def initialize(site)
      @site = site
    end

    # Cleans up the site's destination directory
    def cleanup!
      FileUtils.rm_rf(obsolete_files)
    end

    private

    # Private: The list of files and directories to be deleted during cleanup process
    #
    # Returns an Array of the file and directory paths
    def obsolete_files
      out = (existing_files - new_files - new_dirs + replaced_files).to_a
      Bridgetown::Hooks.trigger :clean, :on_obsolete, out
      @new_files = @new_dirs = nil
      out
    end

    # Private: The list of existing files, apart from those included in
    # keep_files and hidden files.
    #
    # Returns a Set with the file paths
    def existing_files
      files = Set.new
      regex = keep_file_regex
      dirs = keep_dirs

      Utils.safe_glob(site.in_dest_dir, ["**", "*"], File::FNM_DOTMATCH).each do |file|
        next if file =~ HIDDEN_FILE_REGEX || file =~ regex || dirs.include?(file)

        files << file
      end

      files
    end

    # Private: The list of files to be created when site is built.
    #
    # Returns a Set with the file paths
    def new_files
      @new_files ||= Set.new.tap do |files|
        site.each_site_file do |item|
          files << if item.method(:destination).arity == 1
                     item.destination(site.dest)
                   else
                     item.destination.output_path
                   end
        end
      end
    end

    # Private: The list of directories to be created when site is built.
    # These are the parent directories of the files in #new_files.
    #
    # Returns a Set with the directory paths
    def new_dirs
      @new_dirs ||= new_files.flat_map { |file| parent_dirs(file) }.to_set
    end

    # Private: The list of parent directories of a given file
    #
    # Returns an Array with the directory paths
    def parent_dirs(file)
      parent_dir = File.dirname(file)
      if parent_dir == site.dest
        []
      else
        parent_dirs(parent_dir).unshift(parent_dir)
      end
    end

    # Private: The list of existing files that will be replaced by a directory
    # during build
    #
    # Returns a Set with the file paths
    def replaced_files
      new_dirs.select { |dir| File.file?(dir) }.to_set
    end

    # Private: The list of directories that need to be kept because they are
    # parent directories of files specified in keep_files
    #
    # Returns a Set with the directory paths
    def keep_dirs
      site.config.keep_files.flat_map { |file| parent_dirs(site.in_dest_dir(file)) }.to_set
    end

    # Private: Creates a regular expression from the config's keep_files array
    #
    # Examples
    #   ['.git','.svn'] with site.dest "/myblog/_site" creates
    #   the following regex: /\A\/myblog\/_site\/(\.git|\/.svn)/
    #
    # Returns the regular expression
    def keep_file_regex
      %r!\A#{Regexp.quote(site.dest)}/(#{Regexp.union(site.config.keep_files).source})!
    end
  end
end
