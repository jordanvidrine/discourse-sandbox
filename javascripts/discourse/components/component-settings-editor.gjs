import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array } from "@ember/helper";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { htmlSafe } from "@ember/template";
import { TrackedObject } from "@ember-compat/tracked-built-ins";
import { eq } from "truth-helpers";
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
  @tracked currentComponentSettings = new TrackedObject();
  @tracked settingsObject = null;
  currentThemeId = currentThemeId();

  get setting() {
    return this.args.setting;
  }

  @action
  async getComponentData() {
    try {
      const components = await ajax(`/admin/customize/components.json`, {
        type: "GET",
      });

      const searchBannerComponent = components.themes.find(
        (theme) => theme.name === "Search Banner"
      );

      this.currentComponentId = searchBannerComponent.id;

      searchBannerComponent.settings.forEach((setting) => {
        this.currentComponentSettings[setting.setting] = new TrackedObject(
          setting
        );
      });
    } catch {}
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
  async toggleSetting(setting) {
    const newValue = !setting.value;

    try {
      this.currentComponentSettings[setting.setting].value = newValue;

      await ajax(`/admin/themes/${this.currentComponentId}/setting`, {
        type: "PUT",
        data: { name: setting.setting, value: newValue },
      });
    } catch (error) {
      this.currentComponentSettings[setting.setting].value = setting.value;
      popupAjaxError(error);
    }
  }

  <template>
    <DMenu
      @identifier="theme-setting-setter"
      @triggers={{array "click"}}
      @placementStrategy="fixed"
      class="theme-setting-setter btn-transparent"
      @onShow={{this.getComponentData}}
    >
      <:trigger>
        {{icon "cog"}}
      </:trigger>
      <:content>
        {{#each-in this.currentComponentSettings as |key setting|}}
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
                @setting={{setting}}
                @toggleSetting={{this.toggleSetting}}
              />
              {{! possibly need to change all of these settings into a form and save on submit }}
            {{/if}}
          </div>
        {{/each-in}}
      </:content>
    </DMenu>
  </template>
}
