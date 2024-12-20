import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import DToggleSwitch from "discourse/components/d-toggle-switch";


export default class ComponentSettingsSelect extends Component {

  <template>
      <DToggleSwitch
        @state={{this.args.currentValue}}
        {{on "click" (fn this.args.toggleSetting this.args.setting)}}
        class="component-settings-toggle"
        />
  </template>
}
