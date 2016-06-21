module SpiderCore
  module FieldDSL

    # Get a field on current page.
    #
    # @param display [String] display name
    def field(display, pattern, opts = {}, &block)
      actions << lambda {
        action_for(:field, {display: display, pattern: pattern}, opts, &block)
      }
    end

    def fields(display, pattern, opts = {}, &block)
      actions << lambda {
        action_for(:fields, {display: display, pattern: pattern}, opts, &block)
      }
    end

    def foreach(pattern, opts = {}, &block)
      return unless block_given?

      actions << lambda {
        scan_all(pattern, opts).each do |element|
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
          scan_first action_opts[:pattern]
        when :fields
          scan_all action_opts[:pattern], opts
        else
          raise 'Unknow action.'
        end

        put(
          action_opts[:display].to_s,
          handle_elements(elements, &block)
        )
      rescue Exception => err
        logger.fatal("Caught exception when get `#{action_opts[:pattern]}`.")
        logger.fatal(err)
      end
    end

  end
end
