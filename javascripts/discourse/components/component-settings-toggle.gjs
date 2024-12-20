import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import DToggleSwitch from "discourse/components/d-toggle-switch";

export default class ComponentSettingsSelect extends Component {
  <template>
    {{log @setting}}
    <DToggleSwitch
      @state={{@setting.value}}
      {{on "click" (fn @toggleSetting @setting)}}
      class="component-settings-toggle"
    />
  </template>
}
