self: final: prev: {
  nomics = prev.nomics // {
    trivial = prev.nomics.trivial // {
      versionSuffix =
        ".${final.substring 0 8 (self.lastModifiedDate or "19700101")}.${self.shortRev or "dirty"}";

      revisionWithDefault = default: self.rev or default;
    };
  };
}
