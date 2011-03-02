require 'rubygems'

module LOGGING
  class Logging
    
    # General purpose logging
    def logging(request, actiontype, lat=nil, lng=nil, var1=nil, var2=nil)

      if request.env["HTTP_X_USER_ID"].nil?
        facebook_id =  params[:id]
      else
        facebook_id = request.env["HTTP_X_USER_ID"]
      end

      if !request.env["HTTP_X_VAR1"].nil?
        var1 = request.env["HTTP_X_VAR1"]
      end    
      if !request.env["HTTP_X_VAR2"].nil?
        var2 = request.env["HTTP_X_VAR2"]
      end
      if !request.env["HTTP_X_VAR3"].nil?
        var3 = request.env["HTTP_X_VAR3"]
      end
      if !request.env["HTTP_X_VAR4"].nil?
        var4 = request.env["HTTP_X_VAR4"]
      end
      
      logs = Logs.create(
        :event_timestamp => Time.now,
        :session_starttime => request.env["HTTP_X_SESSION_KEY"].nil? ? '1900-01-01' : Time.at(request.env["HTTP_X_SESSION_KEY"].to_i),
        :udid => request.env["HTTP_X_UDID"].nil? ? nil: request.env["HTTP_X_UDID"],
        :device_model => request.env["HTTP_X_DEVICE_MODEL"].nil? ? nil: request.env["HTTP_X_DEVICE_MODEL"],
        :system_name => request.env["HTTP_X_SYSTEM_NAME"].nil? ? nil: request.env["HTTP_X_SYSTEM_NAME"],
        :system_version => request.env["HTTP_X_SYSTEM_VERSION"].nil? ? nil: request.env["HTTP_X_SYSTEM_VERSION"],
        :app_version => request.env["HTTP_X_APP_VERSION"].nil? ? nil: request.env["HTTP_X_APP_VERSION"],
        :facebook_id => facebook_id.nil? ? nil: facebook_id,
        :connection_type => request.env["HTTP_X_CONNECTION_TYPE"].nil? ? nil: request.env["HTTP_X_CONNECTION_TYPE"],
        :language => request.env["HTTP_X_USER_LANGUAGE"].nil? ? nil: request.env["HTTP_X_USER_LANGUAGE"],
        :locale => request.env["HTTP_X_USER_LOCALE"].nil? ? nil: request.env["HTTP_X_USER_LOCALE"],
        :lat => lat.nil? ? nil: lat,
        :lng => lng.nil? ? nil: lng,
        :action_type => actiontype.nil? ? nil: actiontype,
        :var1 => var1.nil? ? nil: var1,
        :var2 => var2.nil? ? nil: var2,
        :var3 => var3.nil? ? nil: var3,
        :var4 => var4.nil? ? nil: var4
      )

    end

end
