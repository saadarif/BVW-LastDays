<script>
  import { themes } from '../config.js';
	import { getContext } from 'svelte';

	export let theme = getContext('theme');
  export let bgimage = './img/output_cp.png';
  export let bgcolor = null;
  export let bgfixed = false;
  export let center = true;
  export let short = false;

  let style = '';

  if (bgimage) {
    style += `background-image: url(${bgimage});`;
  } else {
    style += 'background-image: none;';
  }

  if (bgfixed) {
    style += ' background-attachment: fixed;';
  }

  // left: 100px; top: -50px
</script>

<style>
  .short {
    min-height: 100vh;
  }
  .v-padded {
    box-sizing: border-box;
    padding: 100px 0;
  }
</style>

<header style="color: {themes[theme]['text']}; background-color: {bgcolor ? bgcolor : themes[theme]['background']}; {style}" class:short>
	<div class="v-padded col-wide middle" style="position: relative; " class:short class:height-full={!short}>
		<div class:center>
			<slot></slot>
    </div>
	</div>
</header>

