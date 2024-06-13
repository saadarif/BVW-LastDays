<script>
	import { themes } from '../config.js';
	import { getContext } from 'svelte';

	export let theme = getContext('theme');
	export let center = true;
	export let wide = false;
	export let short = false;
	//add image to filler
	export let bgimage = null;
	export let bgfixed = false;

	let style = '';

  	if (bgimage) {
    	style += `background-image: url(${bgimage});`;
  	} else {
    	style += 'background-image: none;';
 	 }

  	if (bgfixed) {
    	style += ' background-attachment: fixed;';
 	 }
</script>

<style>
	section {
		padding: 36px 0;
	}
	.short {
		min-height: 30vh;
	}
</style>

<section style="color: {themes[theme]['text']}; background-color: {themes[theme]['background']}; {style}">
	<div class="middle" class:center class:col-medium={!wide} class:col-wide={wide} class:height-full={!short} class:short>
		<slot></slot>
	</div>
</section>