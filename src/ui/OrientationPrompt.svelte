<script>
    import { onMount } from 'svelte';

    let isPortrait = false;

    const checkOrientation = () => {
        if (window.matchMedia("(orientation: portrait)").matches) {
            isPortrait = true;
        } else {
            isPortrait = false;
        }
    };

    onMount(() => {
        checkOrientation();
        window.addEventListener('orientationchange', checkOrientation);

        return () => {
            window.removeEventListener('orientationchange', checkOrientation);
        };
    });
</script>

<style>
    .orientation-prompt {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        display: flex;
        justify-content: center;
        align-items: center;
        background-color: rgba(0, 0, 0, 0.8);
        color: white;
        font-size: 1.5em;
        text-align: center;
        z-index: 1000;
    }
</style>

{#if isPortrait}
    <div class="orientation-prompt">
        Please rotate your device horizontally for the best viewing experience.
    </div>
{/if}