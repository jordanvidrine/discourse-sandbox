import Component from "@glimmer/component";
import { array } from "@ember/helper";
import { on } from "@ember/modifier";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { currentThemeId } from "discourse/lib/theme-selector";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { action } from "@ember/object";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import DButton from "discourse/components/d-button";
import icon from "discourse-common/helpers/d-icon";
import DMenu from "float-kit/components/d-menu";
import { fn } from "@ember/helper";
import AdminConfigAreaCard from "admin/components/admin-config-area-card";


export default class themeSettingSetter extends Component {
  currentThemeId = currentThemeId();
  @tracked currentComponentId = null;
  @tracked currentComponentSettings = null;
  @tracked settingsObject = null;

  get setting() {
    return this.args.setting;
  }

  @action
  getComponentData() {
    return ajax(`/admin/customize/components.json`, {
      type: "GET",
    }).then((result) => {
      result.themes.find((theme) => {
        if (theme.name === "sandbox component") {
              this.currentComponentId = theme.id;
              if (theme.settings) {
                let settings = {}
                theme.settings.forEach((setting) => {
                  settings[setting.setting] = setting.value;
                });
                this.currentComponentSettings = settings;
                this.settingsObject = theme.settings;
              }
              console.log(this.currentComponentId);
              console.log(this.currentComponentSettings);
              return true;
            }
              return false;
          });
    });
  }

  @action
  setSetting(setting_name, setting_value) {
    return ajax(`/admin/themes/${this.currentComponentId}/setting`, {
      type: 'PUT',
      data: {
          name: setting_name,
          value: setting_value
        }
    }).catch(popupAjaxError);
  }

  @action
  async toggleSetting(setting_name) {    
    ajax(`/admin/themes/${this.currentComponentId}/setting`, {
      type: 'PUT',
      data: {
          name: setting_name,
          value: !this.currentComponentSettings[setting_name]
        }
    }).catch(popupAjaxError);
    this.currentComponentSettings[setting_name] = !this.currentComponentSettings[setting_name];
  }

  <template>
    <DMenu
      @identifier="theme-setting-setter"
      @triggers={{array "click"}}
      @placementStrategy="fixed"
      class="theme-setting-setter"
      {{didInsert this.getComponentData}}
      >
        <:trigger>
          {{icon "cog"}}
        </:trigger>
        <:content> 
          <DToggleSwitch
            @state={{this.currentComponentSettings.example_setting}}
            {{on "click" (fn this.toggleSetting "example_setting")}}
          />
        </:content>
      </DMenu>
    {{!-- <DButton @action={{this.getComponentId}} class="new-class" />
    <DButton @action={{fn (this.setSetting "example_setting" this.currentComponentSettings.example_setting)}} class="new-class" /> --}}
  </template>

}
