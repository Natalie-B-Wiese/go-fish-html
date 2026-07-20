import {Controller} from '@hotwired/stimulus'

const sidebarStyleOptions = {
    drawer: 'sidebar--drawer',
    compact: 'sidebar--compact',
    rail: 'sidebar--rail',
}

export default class extends Controller {
    static targets = [ "sidebar" ]

    connect() {
        console.log("service worker controller.js connected")

        this.applySidebarStyle(this.getSidebarStyle(window.innerWidth))

        // Window Resize
        window.addEventListener('resize', this.updateSidebarStyle)
    }

    disconnect() {
        console.log("service worker controller.js disconnected")
        window.removeEventListener('resize', this.updateSidebarStyle)
    }

    updateSidebarStyle = () => {
        this.applySidebarStyle(this.getSidebarStyle(window.innerWidth))
    }
    

    getSidebarStyle = (width) => {
        let newStyle = sidebarStyleOptions['drawer']

        if (window.innerWidth <= 1024) {
            newStyle = sidebarStyleOptions['compact']
        }

        if (window.innerWidth <= 768) {
            newStyle = sidebarStyleOptions['rail']
        }

        return newStyle
    }

    applySidebarStyle = (newStyle) => {
        this.sidebarTarget.classList.remove(sidebarStyleOptions['drawer'])
        this.sidebarTarget.classList.remove(sidebarStyleOptions['compact'])
        this.sidebarTarget.classList.remove(sidebarStyleOptions['rail'])
        this.sidebarTarget.classList.add(newStyle)
    }        
}