module SpiderCore
  module FieldDSL

    # Get a field on current page.
    #
    # @param display [String] display name
    def field(display, pattern, opts = {}, &block)
      kind = opts[:kind] || :css
      actions << lambda {
        action_for(:field, {display: display, pattern: pattern, kind: kind}, opts, &block)
      }
    end

    def css_field(display, pattern, opts = {}, &block)
      field(display, pattern, opts.merge(kind: :css), &block)
    end

    def xpath_field(display, pattern, opts = {}, &block)
      field(display, pattern, opts.merge(kind: :xpath), &block)
    end

    def fields(display, pattern, opts = {}, &block)
      kind = opts[:kind] || :css
      actions << lambda {
        action_for(:fields, {display: display, pattern: pattern, kind: kind}, opts, &block)
      }
    end

    def css_fields(display, pattern, opts = {}, &block)
      fields(display, pattern, opts.merge(kind: :css), &block)
    end

    def xpath_fields(display, pattern, opts = {}, &block)
      fields(display, pattern, opts.merge(kind: :xpath), &block)
    end

    def foreach(pattern, opts = {}, &block)
      return unless block_given?
      kind     = opts[:kind] || :css
      actions << lambda {
        scan_all(kind, pattern).each do |element|
          yield(element)
        end
      }
    end

    protected

    def action_for(action, action_opts = {}, opts = {}, &block)
      begin
        logger.info "Start to get `#{action_opts[:pattern]}` displayed `#{action_opts[:display]}`."

        elements = case action
        when :field
          scan_first(action_opts[:kind], action_opts[:pattern])
        when :fields
          scan_all(action_opts[:kind], action_opts[:pattern], opts)
        else
          raise 'Unknow action.'
        end

        make_field_result( action_opts[:display], handle_elements(elements, &block) )
      rescue Exception => err
        logger.fatal("Caught exception when get `#{action_opts[:pattern]}`.")
        logger.fatal(err)
      end
    end

    def make_field_result(display, field)
      current_location[:field] ||= []
      current_location[:field] << {display => field}
    end

  end
end
