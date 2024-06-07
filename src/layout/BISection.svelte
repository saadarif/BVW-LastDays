<script>
/* This component includes a text section in the middle with an image on the left*/
	import { themes } from '../config.js';
	import { getContext } from 'svelte';

	export let theme = getContext('theme');
</script>


<style>
	.section-container {
	  display: flex;
	  flex-direction: row;
	  justify-content: center;
	  align-items: center;
	  width: 100%;
	  padding: .5rem;
	  box-sizing: border-box;
	  color: var(--text-color);
	  background-color: var(--background-color);
	}
  
	.image-slot {
	  flex: 0 0 auto;
	  margin-right: 2rem; /* Adjust the margin between image and text as needed */
      margin-bottom: 1rem; /* Space between image and text on mobile */
	 
	}

	.spacer {
		display: none;
  	}
	  

	.text-slot {
	  flex: 0 0 50%;
	  text-align: left;
      max-width: 600px; /* Optional: limit the maximum width of the text for better layout */
  
	}
  

	.image-slot img {
	  max-width: 100%;
	  height: auto;
	}
  </style>
  
  <section class="section-container" style="--text-color: {themes[theme].text}; --background-color: {themes[theme].background};">
	<div class="image-slot">
	  <slot name="image"></slot>
	</div>
	<div class="text-slot col-medium">
	  <slot></slot>
	</div>
	<div class="spacer"></div>
  </section>


<!-- <section style="color: {themes[theme]['text']}; background-color: {themes[theme]['background']}">
	<div class="col-medium">
		<slot></slot>
	</div>
</section> -->