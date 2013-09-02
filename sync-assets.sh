#!/usr/bin/env bash
rsync -azv ./public/assets/ worlize@pxy2.dallas.worlize.com:/app/frontend/current/public/assets --progress