module Grip
  module Dsl
    module Macros
      HTTP_METHODS = %i(get post put patch delete options head)

      macro pipeline(name, pipes)
        {{pipes}}.each do |pipe|
          @pipeline_handler.add_pipe({{name}}, pipe)
        end
      end

      macro pipe_through(valve)
        @valve = {{valve}}
        case {{valve}}
        when Symbol
          @valves.push({{valve}})
        else
          # Ignore this condition
        end
      end

      macro scope(path)
        size = @valves.size

        if {{path}} != "/"
          @scopes.push({{path}})
        end

        {{yield}}

        @valves.pop() if @valves.size != 0 && @valves.size != size

        if {{path}} != "/"
          @scopes.pop()
        end

        @valves.pop() if @scopes.size == 0 && @valves.size != 0
      end

      {% for http_method in HTTP_METHODS %}
        macro {{http_method.id}}(route, resource, **kwargs)
          \{% if kwargs[:as] %}
            @http_handler.add_route(
              {{http_method}}.to_s.upcase,
              "#{@scopes.join()}#{\{{route}}}",
              \{{resource}}.new.as(Grip::Controllers::Base),
              @valves.clone(),
              -> (context : HTTP::Server::Context) {
                \{{ resource }}.new.as(\{{resource}}).\{{kwargs[:as].id}}(context)
              }
            )
          \{% else %}
            @http_handler.add_route(
              {{http_method}}.to_s.upcase,
              "#{@scopes.join()}#{\{{route}}}",
              \{{resource}}.new.as(Grip::Controllers::Base),
              @valves.clone(),
              nil
            )
          \{% end %}

          \{% for method in resource.resolve.methods %}
            \{% route_annotation = method.annotation(Grip::Annotations::Route) %}
            \{% controller_annotation = resource.resolve.annotation(Grip::Annotations::Controller) %}
            \{% if route_annotation && controller_annotation %}
              @swagger_builder.add(
                Swagger::Controller.new(
                  \{{ controller_annotation[:name] }} || "#{\{{ resource }}.to_s}",
                  \{{ controller_annotation[:description] }},
                  [
                    Swagger::Action.new(
                      method: {{http_method}}.to_s || "",
                      # This looks quite painful but it is what it is :)
                      route: "/" + "#{@scopes.join()}#{\{{route}}}".split("/", remove_empty: true).map! { |path|
                        if path.includes?(":")
                          "{#{path.gsub(":", "")}}"
                        else
                          path
                        end }.join("/"),
                      responses: \{{route_annotation[:responses]}} || [] of Swagger::Response,
                      request: \{{route_annotation[:request]}},
                      summary: \{{route_annotation[:summary]}},
                      parameters: \{{route_annotation[:parameters]}},
                      description: \{{route_annotation[:description]}},
                      authorization: \{{route_annotation[:authorization]}} || false,
                      deprecated: \{{route_annotation[:deprecated]}} || false
                    )
                  ]
                )
              )
            \{% end %}
          \{% end %}
        end
      {% end %}

      macro forward(route, resource, **kwargs)
        @forward_handler.add_route(
          "ALL",
          "#{@scopes.join()}#{{{route}}}",
          {{resource}}.new({{**kwargs}}).as(Grip::Controllers::Base),
          @valves.clone(),
          nil
        )
      end

      macro error(error_code, resource)
        @exception_handler.handlers[{{error_code}}] = {{resource}}.new
      end

      macro ws(route, resource, **kwargs)
        @websocket_handler.add_route("", "#{@scopes.join()}#{{{route}}}", {{ resource }}.new, @valves.clone(), nil)
      end
    end
  end
end
