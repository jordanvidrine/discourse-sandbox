import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { htmlSafe } from "@ember/template";
import { array } from "@ember/helper";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "truth-helpers";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { TrackedObject } from "@ember-compat/tracked-built-ins";
import DButton from "discourse/components/d-button";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { currentThemeId } from "discourse/lib/theme-selector";
import icon from "discourse-common/helpers/d-icon";
import DMenu from "float-kit/components/d-menu";
import ComponentSettingsSelect from "../components/component-settings-select";
import ComponentSettingsToggle from "../components/component-settings-toggle";


export default class themeSettingSetter extends Component {
  @tracked currentComponentId = null;
  @tracked currentComponentSettings = new TrackedObject([]);
  @tracked settingsObject = null;
  currentThemeId = currentThemeId();

  get setting() {
    return this.args.setting;
  }

  @action
  getComponentData() {
    return ajax(`/admin/customize/components.json`, {
      type: "GET",
    }).then((result) => {
      result.themes.find((theme) => {
        if (theme.name === "Search Banner") {
          this.currentComponentId = theme.id;
          if (theme.settings) {
            theme.settings.forEach((setting) => {
              // stores object of settings
              // this.currentComponentSettings[setting.setting] = setting;
              this.currentComponentSettings.push(setting); // using array is iterable in template
            });
          }
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
      type: "PUT",
      data: {
        name: setting_name,
        value: setting_value,
      },
    }).catch(popupAjaxError);
  }

  @action
  async toggleSetting(settingName) {
    console.log(settingName);
    
    try {
      ajax(`/admin/themes/${this.currentComponentId}/setting`, {
        type: "PUT",
        data: {
          name: settingName,
          value: !this.currentComponentSettings[settingName],
        },
      });

      this.currentComponentSettings[settingName] =
        !this.currentComponentSettings[settingName];
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  cleanupComponentData() {
    this.currentComponentSettings = new TrackedObject([]);
  }

  <template>
    <DMenu
      @identifier="theme-setting-setter"
      @triggers={{array "click"}}
      @placementStrategy="fixed"
      class="theme-setting-setter btn-transparent"
      @onShow={{this.getComponentData}}
      @onClose={{this.cleanupComponentData}}
    >
      <:trigger>
        {{icon "cog"}}
      </:trigger>
      <:content>
        {{#each this.currentComponentSettings as |setting|}}
          <div class="theme-setting-setter__setting">
            {{#if (eq setting.type "enum")}}
              <ComponentSettingsSelect
                @values={{setting.valid_values}}
                @label={{setting.setting}}
                @currentValue={{setting.value}}
              />
            {{/if}}
            {{#if (eq setting.type "bool")}}
              <ComponentSettingsToggle
                @setting={{setting.setting}}
                @currentValue={{setting.value}}
                @toggleSetting={{this.toggleSetting}}
              />
              {{!-- possibly need to change all of these settings into a form and save on submit --}}
            {{/if}}
          </div>
        {{/each}}
      </:content>
    </DMenu>
  </template>
}
