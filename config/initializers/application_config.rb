module Worlize
  def self.config
    @config
  end
  def self.load_config
    raw_config = YAML.load_file("#{Rails.root}/config/config.yml")
    @config = raw_config['global']
    @config.merge!(raw_config[Rails.env])
  end
end

Worlize::load_config