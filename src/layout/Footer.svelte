<script>
	import { themes } from '../config.js';
	import { getContext } from 'svelte';

	export let theme = getContext('theme');
</script>

<footer style="color: {themes[theme]['text']}; background-color: {themes[theme]['pale']};">
	<div class="col-wide" data-analytics="footer">
		<a href="https://brookes.ac.uk">
			{#if theme == 'dark'}
			<img
				class="logo-img"
				src="./img/brookes-logo-home.png"
				alt="Oxford Brookes University" />
			{:else}
			<img
				class="logo-img"
				src="./img/brookes-logo-home.png"
				alt="Oxford Brookes University" />
			{/if}
		</a>
		<ul>
			<li><a href="https://saadarif.github.io/" class="link" style="color: {themes[theme]['text']}">Contact author</a></li>
			<li><a href="https://www.biorxiv.org/content/10.1101/2023.12.19.572305v4.abstract" class="link" style="color: {themes[theme]['text']}">More info</a></li>
			<li><a href="https://lizzieharper.co.uk/" class="link" style="color: {themes[theme]['text']}">More art</a></li>
		</ul>
		<hr style="border-top-color: {themes[theme]['muted']}" />
		<div class="license">
			<a href="https://creativecommons.org/licenses/by-sa/4.0/">
				<img
				class="copr-img"
				style="width: 90px; height: 31px"
				src="./img/by-sa.png"
				alt="by-sa license image"
				 /></a> All content is under a <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0 </a> license unless otherwise stated.
			 	The header meadow illustration is used under license which is <strong>copyright</strong> to
				<a
				href="https://lizzieharper.co.uk/"
				class="link"
				target="_blank"
				rel="noopener"
				style="color: {themes[theme]['text']}">Lizzie Harper</a>. 
				This page was developed using the excellent <a href="https://github.com/ONSvisual/svelte-scrolly/"> ONS Scrollytelling Github repo</a>.
			
	</div>
</footer>

<style>
	footer {
		padding-bottom: 72px;
		padding-top: 36px;
		font-size: 18px;
	}
	footer a.link {
		-webkit-box-sizing: border-box;
		box-sizing: border-box;
		text-decoration: underline;
		display: inline-block;
	}
	footer a.link:hover {
		text-decoration: none;
	}
	footer a.link:active {
		outline: 3px solid transparent;
		background-color: #fd0;
		-webkit-box-shadow: 0 -2px #fd0, 0 4px #222;
		box-shadow: 0 -2px #fd0, 0 4px #222;
		color: #222;
		text-decoration: none;
	}
	footer hr {
		margin-bottom: 27px;
		margin-top: 36px;
		border: none;
		border-top: 1px solid #777;
	}
	ul {
		padding: 0;
		margin: 0;
	}
	li {
		margin-right: 18px;
		display: inline-block;
	}
	.logo-img {
		margin-bottom: 27px;
	}
	.copr-img {
		margin: 0 0.5rem 0.2rem 0;
		width: 25px;
		height: 25px;
		vertical-align: middle;
	}
	.license {
		vertical-align: top;
	}
	a img:hover {
		cursor: pointer;
	}
</style>