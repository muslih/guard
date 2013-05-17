module Guard

  # @deprecated
  # @see DSL
  #
  class Dsl

    # @deprecated Use `Guard::Guardfile::Evaluator.new(options).evaluate_guardfile` instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to upgrade for Guard 2.0
    #
    def self.evaluate_guardfile(options = {})
      ::Guard::UI.deprecation(::Guard::Deprecator::EVALUATE_GUARDFILE_DEPRECATION)
      ::Guard::Guardfile::Evaluator.new(options).evaluate_guardfile
    end

  end

  # The DSL class provides the methods that are used in each `Guardfile` to describe
  # the behaviour of Guard.
  #
  # The main keywords of the DSL are `guard` and `watch`. These are necessary to define
  # the used Guard plugins and the file changes they are watching.
  #
  # You can optionally group the Guard plugins with the `group` keyword and ignore and filter certain paths
  # with the `ignore` and `filter` keywords.
  #
  # You can set your preferred system notification library with `notification` and pass
  # some optional configuration options for the library. If you don't configure a library,
  # Guard will automatically pick one with default options (if you don't want notifications,
  # specify `:off` as library). @see ::Guard::Notifier for more information about the supported libraries.
  #
  # A more advanced DSL use is the `callback` keyword that allows you to execute arbitrary
  # code before or after any of the `start`, `stop`, `reload`, `run_all`, `run_on_changes`,
  # `run_on_additions`, `run_on_modifications` and `run_on_removals` Guard plugins method.
  # You can even insert more hooks inside these methods.
  # Please [checkout the Wiki page](https://github.com/guard/guard/wiki/Hooks-and-callbacks) for more details.
  #
  # The DSL will also evaluate normal Ruby code.
  #
  # There are two possible locations for the `Guardfile`:
  # - The `Guardfile` in the current directory where Guard has been started
  # - The `.Guardfile` in your home directory.
  #
  # In addition, if a user configuration `.guard.rb` in your home directory is found, it will
  # be appended to the current project `Guardfile`.
  #
  # @see https://github.com/guard/guard/wiki/Guardfile-examples
  #
  class DSL

    require 'guard/guardfile'
    require 'guard/interactor'
    require 'guard/notifier'
    require 'guard/ui'
    require 'guard/watcher'

    # @deprecated Use `Guard::Guardfile::Evaluator.new(options).evaluate_guardfile` instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to upgrade for Guard 2.0
    #
    def self.evaluate_guardfile(options = {})
      ::Guard::UI.deprecation(::Guard::Deprecator::EVALUATE_GUARDFILE_DEPRECATION)
      ::Guard::Guardfile::Evaluator.new(options).evaluate_guardfile
    end

    # Set notification options for the system notifications.
    # You can set multiple notifications, which allows you to show local
    # system notifications and remote notifications with separate libraries.
    # You can also pass `:off` as library to turn off notifications.
    #
    # @example Define multiple notifications
    #   notification :growl_notify
    #   notification :ruby_gntp, :host => '192.168.1.5'
    #
    # @see Guard::Notifier for available notifier and its options.
    #
    # @param [Symbol, String] notifier the name of the notifier to use
    # @param [Hash] options the notification library options
    #
    def notification(notifier, options = {})
      ::Guard::Notifier.add_notification(notifier.to_sym, options, false)
    end

    # Sets the interactor options or disable the interactor.
    #
    # @example Pass options to the interactor
    #   interactor :option1 => 'value1', :option2 => 'value2'
    #
    # @example Turn off interactions
    #   interactor :off
    #
    # @param [Symbol, Hash] options either `:off` or a Hash with interactor options
    #
    def interactor(options)
      if options == :off
        ::Guard::Interactor.enabled = false

      elsif options.is_a?(Hash)
        ::Guard::Interactor.options = options

      else
        ::Guard::UI.deprecation(::Guard::Deprecator::DSL_METHOD_INTERACTOR_DEPRECATION)
      end
    end

    # Declares a group of Guard plugins to be run with `guard start --group group_name`.
    #
    # @example Declare two groups of Guard plugins
    #   group :backend do
    #     guard :spork
    #     guard :rspec
    #   end
    #
    #   group :frontend do
    #     guard :passenger
    #     guard :livereload
    #   end
    #
    # @param [Symbol, String] name the group name called from the CLI
    # @param [Hash] options the options accepted by the group
    # @yield a block where you can declare several guards
    #
    # @see Guard.add_group
    # @see #guard
    # @see Guard::DSLDescriber
    #
    def group(name, options = {})
      name = name.to_sym

      if block_given?
        ::Guard.add_group(name, options)
        @current_group = name

        yield

        @current_group = nil
      else
        ::Guard::UI.error "No Guard plugins found in the group '#{ name }', please add at least one."
      end
    end

    # Declares a Guard plugin to be used when running `guard start`.
    #
    # The name parameter is usually the name of the gem without
    # the 'guard-' prefix.
    #
    # The available options are different for each Guard implementation.
    #
    # @example Declare a Guard without `watch` patterns
    #   guard :rspec
    #
    # @example Declare a Guard with a `watch` pattern
    #   guard :rspec do
    #     watch %r{.*_spec.rb}
    #   end
    #
    # @param [String] name the Guard plugin name
    # @param [Hash] options the options accepted by the Guard plugin
    # @yield a block where you can declare several watch patterns and actions
    #
    # @see Guard.add_guard
    # @see #group
    # @see #watch
    # @see Guard::DSLDescriber
    #
    def guard(name, options = {})
      @watchers  = []
      @callbacks = []
      @current_group ||= :default

      yield if block_given?

      options.merge!(:group => @current_group, :watchers => @watchers, :callbacks => @callbacks)
      ::Guard.add_guard(name, options)
    end

    # Defines a pattern to be watched in order to run actions on file modification.
    #
    # @example Declare watchers for a Guard
    #   guard :rspec do
    #     watch('spec/spec_helper.rb')
    #     watch(%r{^.+_spec.rb})
    #     watch(%r{^app/controllers/(.+).rb}) { |m| 'spec/acceptance/#{m[1]}s_spec.rb' }
    #   end
    #
    # @param [String, Regexp] pattern the pattern that Guard must watch for modification
    # @yield a block to be run when the pattern is matched
    # @yieldparam [MatchData] m matches of the pattern
    # @yieldreturn a directory, a filename, an array of directories / filenames, or nothing (can be an arbitrary command)
    #
    # @see Guard::Watcher
    # @see #guard
    #
    def watch(pattern, &action)
      @watchers << ::Guard::Watcher.new(pattern, action)
    end

    # Defines a callback to execute arbitrary code before or after any of
    # the `start`, `stop`, `reload`, `run_all`, `run_on_changes`, `run_on_additions`,
    # `run_on_modifications` and `run_on_removals` plugin method.
    #
    # @param [Array] args the callback arguments
    # @yield a block with listeners
    #
    # @see Guard::Hooker
    #
    def callback(*args, &listener)
      listener, events = args.size > 1 ? args : [listener, args[0]]
      @callbacks << { :events => events, :listener => listener }
    end

    # @deprecated Use `ignore` or `ignore!` instead.
    #
    # @example Ignore some paths
    #   ignore_paths ".git", ".svn"
    #
    # @param [Array] paths the list of paths to ignore
    #
    def ignore_paths(*paths)
      ::Guard::UI.deprecation(::Guard::Deprecator::DSL_METHOD_IGNORE_PATHS_DEPRECATION)
    end

    # Ignores certain paths globally.
    #
    # @example Ignore some paths
    #   ignore %r{^ignored/path/}, /man/
    #
    # @param [Regexp] regexps a pattern (or list of patterns) for ignoring paths
    #
    def ignore(*regexps)
      ::Guard.listener = ::Guard.listener.ignore(*regexps)
    end

    # Replaces ignored paths globally
    #
    # @example Ignore only these paths
    #   ignore! %r{^ignored/path/}, /man/
    #
    # @param [Regexp] regexps a pattern (or list of patterns) for ignoring paths
    #
    def ignore!(*regexps)
      ::Guard.listener = ::Guard.listener.ignore!(*regexps)
    end

    # Filters certain paths globally.
    #
    # @example Filter some files
    #   filter /\.txt$/, /.*\.zip/
    #
    # @param [Regexp] regexps a pattern (or list of patterns) for filtering paths
    #
    def filter(*regexps)
      ::Guard.listener = ::Guard.listener.filter(*regexps)
    end

    # Replaces filtered paths globally.
    #
    # @example Filter only these files
    #   filter! /\.txt$/, /.*\.zip/
    #
    # @param [Regexp] regexps a pattern (or list of patterns) for filtering paths
    #
    def filter!(*regexps)
      ::Guard.listener = ::Guard.listener.filter!(*regexps)
    end

    # Configures the Guard logger.
    #
    # * Log level must be either `:debug`, `:info`, `:warn` or `:error`.
    # * Template supports the following placeholders: `:time`, `:severity`,
    #   `:progname`, `:pid`, `:unit_of_work_id` and `:message`.
    # * Time format directives are the same as `Time#strftime` or `:milliseconds`.
    # * The `:only` and `:except` options must be a `RegExp`.
    #
    # @example Set the log level
    #   logger :level => :warn
    #
    # @example Set a custom log template
    #   logger :template => '[Guard - :severity - :progname - :time] :message'
    #
    # @example Set a custom time format
    #   logger :time_format => '%h'
    #
    # @example Limit logging to a Guard plugin
    #   logger :only => :jasmine
    #
    # @example Log all but not the messages from a specific Guard plugin
    #   logger :except => :jasmine
    #
    # @param [Hash] options the log options
    # @option options [String, Symbol] level the log level
    # @option options [String] template the logger template
    # @option options [String, Symbol] time_format the time format
    # @option options [RegExp] only show only messages from the matching Guard plugin
    # @option options [RegExp] except does not show messages from the matching Guard plugin
    #
    def logger(options)
      if options[:level]
        options[:level] = options[:level].to_sym

        unless [:debug, :info, :warn, :error].include? options[:level]
          ::Guard::UI.warning "Invalid log level `#{ options[:level] }` ignored. Please use either :debug, :info, :warn or :error."
          options.delete :level
        end
      end

      if options[:only] && options[:except]
        ::Guard::UI.warning 'You cannot specify the logger options :only and :except at the same time.'

        options.delete :only
        options.delete :except
      end

      # Convert the :only and :except options to a regular expression
      [:only, :except].each do |name|
        if options[name]
          list = [].push(options[name]).flatten.map { |plugin| Regexp.escape(plugin.to_s) }.join('|')
          options[name] = Regexp.new(list, Regexp::IGNORECASE)
        end
      end

      ::Guard::UI.options = ::Guard::UI.options.merge options
    end

    # Sets the default scope on startup
    #
    # @example Scope Guard to a single group
    #   scope :group => :frontend
    #
    # @example Scope Guard to multiple groups
    #   scope :groups => [:specs, :docs]
    #
    # @example Scope Guard to a single plugin
    #   scope :plugin => :test
    #
    # @example Scope Guard to multiple plugins
    #   scope :plugins => [:jasmine, :rspec]
    #
    # @param [Hash] scopes the scope for the groups and plugins
    #
    def scope(scopes = {})
      if ::Guard.options[:plugin].empty?
        ::Guard.options[:plugin] = [scopes[:plugin]] if scopes[:plugin]
        ::Guard.options[:plugin] = scopes[:plugins]  if scopes[:plugins]
      end

      if ::Guard.options[:group].empty?
        ::Guard.options[:group] = [scopes[:group]] if scopes[:group]
        ::Guard.options[:group] = scopes[:groups]  if scopes[:groups]
      end
    end

  end
end
