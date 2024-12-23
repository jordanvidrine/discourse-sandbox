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
      formData[key] = value.value;
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

      searchBannerComponent.settings.forEach((setting) => {
        this.currentComponentSettings[setting.setting] = new TrackedObject(
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
      const baseUrlPattern = /^.*(?=\/uploads)/;
      let cleanUrl = upload.url.replace(baseUrlPattern, '');
      console.log(cleanUrl);
    
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
          {{#each-in this.currentComponentSettings as |key setting|}}
            <div class="theme-setting-setter__setting">
                {{#if (eq setting.type "enum")}}
                  <form.Field
                    @title={{setting.setting}}
                    @name={{setting.setting}}
                    @format="large"
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
                {{/if}}
                {{#if (eq setting.type "upload")}}
                  <form.Field
                    @title={{setting.setting}}
                    @name={{setting.setting}}
                    @onSet={{(fn this.onSetImage setting)}}
                    as |field|>
                      <field.Image @type="theme_setting" />
                    </form.Field>
                {{/if}}
                {{#if (eq setting.type "bool")}}
                  <form.Field
                    @title={{setting.setting}}
                    @name={{setting.setting}}
                    @format="large"
                    as |field|
                    >
                      <field.Toggle/>
                  </form.Field>
                {{/if}}
            </div>
          {{/each-in}}
          <form.Submit @translatedLabel="Save" />
        </Form>
      </:content>
    </DMenu>
  </template>
}
