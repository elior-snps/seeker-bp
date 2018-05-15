# frozen_string_literal: true

# Cloud Foundry Java Buildpack
# Copyright 2013-2017 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/component/base_component'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch Seeker support.
    class SeekerSecurityProvider < JavaBuildpack::Component::BaseComponent
      # (see JavaBuildpack::Component::BaseComponent#detect)
      def detect
        true
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        credentials = @application.services.find_service(FILTER, SEEKER_HOST_SERVICE_CONFIG_KEY)['credentials']
        if credentials!=nill
          credentials.each do |key, value|
            puts "#{key} is #{value}"
          end
        else
          puts "credentials are nil!!"
        end
        assert_configuration_valid(credentials)
        download_tar('', credentials[AGENT_ARTIFACT_SERVICE_CONFIG_KEY], true, @droplet.sandbox)
        @droplet.copy_resources
      end

      # Verefies required agent configuration is present
      def assert_configuration_valid(credentials)
        raise "'#{AGENT_ARTIFACT_SERVICE_CONFIG_KEY}' credential must be set" unless
          credentials[AGENT_ARTIFACT_SERVICE_CONFIG_KEY]
        raise "'#{AGENT_ARTIFACT_SERVICE_CONFIG_KEY}' credential must be set" unless
          credentials[SEEKER_HOST_SERVICE_CONFIG_KEY]
        raise "'#{AGENT_ARTIFACT_SERVICE_CONFIG_KEY}'credential must be set" unless
          credentials[SEEKER_HOST_PORT_SERVICE_CONFIG_KEY]
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        @droplet.java_opts.add_javaagent(@droplet.sandbox + 'seeker-agent.jar')
        @droplet
          .add_environment_variable('SEEKER_SENSOR_HOST', credentials[SEEKER_HOST_SERVICE_CONFIG_KEY])
          .add_environment_variable('SEEKER_SENSOR_HTTP_PORT', credentials[SEEKER_HOST_PORT_SERVICE_CONFIG_KEY])
      end

      SEEKER_HOST_SERVICE_CONFIG_KEY = 'sensor_host'

      SEEKER_HOST_PORT_SERVICE_CONFIG_KEY = 'sensor_port'
      # In the future Seeker's will expose REST endpoint for downloading the agent from the enterprise server (tgz file)
      AGENT_ARTIFACT_SERVICE_CONFIG_KEY = 'agent_uri'
      # seeker service substring
      FILTER = /seeker/

      private_constant :SEEKER_HOST_SERVICE_CONFIG_KEY, :SEEKER_HOST_PORT_SERVICE_CONFIG_KEY,
                       :AGENT_ARTIFACT_SERVICE_CONFIG_KEY, :AGENT_ARTIFACT_SERVICE_CONFIG_KEY

    end

  end
end