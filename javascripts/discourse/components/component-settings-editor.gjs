import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import getURL from "discourse-common/lib/get-url";
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
import Form from "discourse/components/form";


export default class themeSettingSetter extends Component {
  @tracked currentComponentId = null;
  @tracked currentComponentSettings = new TrackedObject();
  @tracked settingsObject = null;
  currentThemeId = currentThemeId();

  get setting() {
    return this.args.setting;
  }

  get formData() {
    let formData = {};
    for (const [key, value] of Object.entries(this.currentComponentSettings)) {
      for (const [settingKey, settingValue] of Object.entries(value)) {
        formData[settingKey] = settingValue.value;
      }
    }    
    return formData;
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

      // building an object, organized by type of setting
      // I do this so I can loop through the object by type in the template
      // rather than looping through all settings
      searchBannerComponent.settings.forEach((setting) => {
        if (this.currentComponentSettings[setting.type] === undefined) {
          this.currentComponentSettings[setting.type] = new TrackedObject();
        }
      });

      // assigning the settings to the object housed under each "type" of setting
      searchBannerComponent.settings.forEach((setting) => {
        this.currentComponentSettings[setting.type][setting.setting] = new TrackedObject(
          setting
        );
      });
    } catch {}
  }

  @action
  async setSetting(setting_name, setting_value) {
    await ajax(`/admin/themes/${this.currentComponentId}/setting`, {
      type: "PUT",
      data: {
        name: setting_name,
        value: setting_value,
      },
    }).catch(popupAjaxError);
  }

  @action
  onSetImage(setting, upload, { set }) { 
    if (upload) {    
      // Remove the base URL from the upload URL (somehow this is needed inside of a theme component)
      const baseUrlPattern = /^.*(?=\/uploads)/;
      let cleanUrl = upload.url.replace(baseUrlPattern, '');
    
      set(`${setting.setting}`, getURL(cleanUrl));
    } else {
      set(`${setting.setting}`, "");
    }
  }

  @action
  formSave(data) {            
    for (const [key, value] of Object.entries(data)) {
     this.setSetting(key, value);
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
        <Form @data={{this.formData}} @onSubmit={{this.formSave}} as |form data|>
          {{#if this.currentComponentSettings.enum}}
          <div class="theme-setting-setter__setting-enum">            
            {{#each-in this.currentComponentSettings.enum as |key setting|}}
              <form.Field
                @title={{setting.setting}}
                @name={{setting.setting}}
                @description={{htmlSafe setting.description}}
                @format="medium"
                as |field|
              >
                <field.Select as |select|>
                  {{#each setting.valid_values as |valueOption|}}
                    <select.Option
                      @value={{valueOption}}
                    >{{valueOption}}</select.Option>
                  {{/each}}
                </field.Select>
              </form.Field>
            {{/each-in}}
          </div>
          {{/if}}
          {{#if this.currentComponentSettings.upload}}
          <div class="theme-setting-setter__setting-upload">
            {{#each-in this.currentComponentSettings.upload as |key setting|}}
              <form.Field
                @title={{setting.setting}}
                @name={{setting.setting}}
                @onSet={{(fn this.onSetImage setting)}}
                @description={{htmlSafe setting.description}}
                @format="medium"
                as |field|>
                  <field.Image @type="theme_setting" />
              </form.Field>
            {{/each-in}}
          </div>
          {{/if}}
          {{#if this.currentComponentSettings.bool}}
          <div class="theme-setting-setter__setting-bool">
            {{#each-in this.currentComponentSettings.bool as |key setting|}}
              <form.Field
                @title={{setting.setting}}
                @name={{setting.setting}}
                @description={{htmlSafe setting.description}}
                @format="medium"
                as |field|
                >
                  <field.Toggle/>
              </form.Field>
            {{/each-in}}
            </div>
            {{/if}}
            {{#if this.currentComponentSettings.string}}
            <div class="theme-setting-setter__setting-string">
              {{#each-in this.currentComponentSettings.string as |key setting|}}
                <form.Field
                  @title={{setting.setting}}
                  @name={{setting.setting}}
                  @description={{htmlSafe setting.description}}
                  @format="medium"
                  as |field|
                  >
                    <field.Input/>
                </form.Field>
              {{/each-in}}
              </div>
              {{/if}}
          <form.Submit @translatedLabel="Save" />
        </Form>
      </:content>
    </DMenu>
  </template>
}
